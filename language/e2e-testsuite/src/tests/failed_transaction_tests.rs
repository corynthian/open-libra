// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

use ol_gas::{
    OLGasMeter, OLGasParameters, StorageGasParameters, LATEST_GAS_FEATURE_VERSION,
};
use ol_language_e2e_tests::{common_transactions::peer_to_peer_txn, executor::FakeExecutor};
use ol_state_view::TStateView;
use ol_types::{
    transaction::ExecutionStatus,
    vm_status::{StatusCode, VMStatus},
};
use ol_vm::{
    data_cache::AsMoveResolver, logging::AdapterLogSchema,
    transaction_metadata::TransactionMetadata, OLVM,
};
use move_core_types::vm_status::StatusCode::TYPE_MISMATCH;

#[test]
fn failed_transaction_cleanup_test() {
    let mut executor = FakeExecutor::from_head_genesis();
    // TODO(Gas): double check this
    let sender = executor.create_raw_account_data(1_000_000, 10);
    executor.add_account_data(&sender);

    let log_context = AdapterLogSchema::new(executor.get_state_view().id(), 0);
    let ol_vm = OLVM::new(executor.get_state_view());
    let data_cache = executor.get_state_view().as_move_resolver();

    let txn_data = TransactionMetadata {
        sender: *sender.address(),
        max_gas_amount: 100_000.into(),
        gas_unit_price: 0.into(),
        sequence_number: 10,
        ..Default::default()
    };

    let gas_params = OLGasParameters::zeros();
    let storage_gas_params = StorageGasParameters::free_and_unlimited();
    let mut gas_meter = OLGasMeter::new(
        LATEST_GAS_FEATURE_VERSION,
        gas_params,
        storage_gas_params,
        10_000,
    );

    // TYPE_MISMATCH should be kept and charged.
    let out1 = ol_vm.failed_transaction_cleanup(
        VMStatus::Error(StatusCode::TYPE_MISMATCH),
        &mut gas_meter,
        &txn_data,
        &data_cache,
        &log_context,
    );
    assert!(!out1.txn_output().write_set().is_empty());
    assert_eq!(out1.txn_output().gas_used(), 90_000);
    assert!(!out1.txn_output().status().is_discarded());
    assert_eq!(
        out1.txn_output().status().status(),
        // StatusCode::TYPE_MISMATCH
        Ok(ExecutionStatus::MiscellaneousError(Some(TYPE_MISMATCH)))
    );

    // Invariant violations should be discarded and not charged.
    let out2 = ol_vm.failed_transaction_cleanup(
        VMStatus::Error(StatusCode::UNKNOWN_INVARIANT_VIOLATION_ERROR),
        &mut gas_meter,
        &txn_data,
        &data_cache,
        &log_context,
    );
    assert!(out2.txn_output().write_set().is_empty());
    assert!(out2.txn_output().gas_used() == 0);
    assert!(out2.txn_output().status().is_discarded());
    assert_eq!(
        out2.txn_output().status().status(),
        Err(StatusCode::UNKNOWN_INVARIANT_VIOLATION_ERROR)
    );
}

#[test]
fn non_existent_sender() {
    let mut executor = FakeExecutor::from_head_genesis();
    let sequence_number = 0;
    let sender = executor.create_raw_account();
    let receiver = executor.create_raw_account_data(100_000, sequence_number);
    executor.add_account_data(&receiver);

    let transfer_amount = 10;
    let txn = peer_to_peer_txn(
        &sender,
        receiver.account(),
        sequence_number,
        transfer_amount,
    );

    let output = &executor.execute_transaction(txn);
    assert_eq!(
        output.status().status(),
        Err(StatusCode::SENDING_ACCOUNT_DOES_NOT_EXIST),
    );
}
