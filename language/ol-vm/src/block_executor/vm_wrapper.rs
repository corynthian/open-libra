// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

use crate::{
    adapter_common::{PreprocessedTransaction, VMAdapter},
    ol_vm::OLVM,
    block_executor::OLTransactionOutput,
    data_cache::{AsMoveResolver, StorageAdapter},
    logging::AdapterLogSchema,
};
use ol_aggregator::{delta_change_set::DeltaChangeSet, transaction::TransactionOutputExt};
use ol_block_executor::task::{ExecutionStatus, ExecutorTask};
use ol_logger::prelude::*;
use ol_state_view::StateView;
use move_core_types::{
    ident_str,
    language_storage::{ModuleId, CORE_CODE_ADDRESS},
    vm_status::VMStatus,
};

pub(crate) struct OLExecutorTask<'a, S> {
    vm: OLVM,
    base_view: &'a S,
}

impl<'a, S: 'a + StateView + Sync> ExecutorTask for OLExecutorTask<'a, S> {
    type Argument = &'a S;
    type Error = VMStatus;
    type Output = OLTransactionOutput;
    type Txn = PreprocessedTransaction;

    fn init(argument: &'a S) -> Self {
        let vm = OLVM::new(argument);

        // Loading `0x1::account` and its transitive dependency into the code cache.
        //
        // This should give us a warm VM to avoid the overhead of VM cold start.
        // Result of this load could be omitted as this is a best effort approach and won't hurt if that fails.
        //
        // Loading up `0x1::account` should be sufficient as this is the most common module
        // used for prologue, epilogue and transfer functionality.

        let _ = vm.load_module(
            &ModuleId::new(CORE_CODE_ADDRESS, ident_str!("account").to_owned()),
            &StorageAdapter::new(argument),
        );

        Self {
            vm,
            base_view: argument,
        }
    }

    // This function is called by the BlockExecutor for each transaction is intends
    // to execute (via the ExecutorTask trait). It can be as a part of sequential
    // execution, or speculatively as a part of a parallel execution.
    fn execute_transaction(
        &self,
        view: &impl StateView,
        txn: &PreprocessedTransaction,
        txn_idx: usize,
        materialize_deltas: bool,
    ) -> ExecutionStatus<OLTransactionOutput, VMStatus> {
        let log_context = AdapterLogSchema::new(self.base_view.id(), txn_idx);

        match self
            .vm
            .execute_single_transaction(txn, &view.as_move_resolver(), &log_context)
        {
            Ok((vm_status, mut output_ext, sender)) => {
                if materialize_deltas {
                    // Keep TransactionOutputExt type for wrapper.
                    output_ext = TransactionOutputExt::new(
                        DeltaChangeSet::empty(),                  // Cleared deltas.
                        output_ext.into_transaction_output(view), // Materialize.
                    );
                }

                if output_ext.txn_output().status().is_discarded() {
                    match sender {
                        Some(s) => trace!(
                            log_context,
                            "Transaction discarded, sender: {}, error: {:?}",
                            s,
                            vm_status,
                        ),
                        None => {
                            trace!(log_context, "Transaction malformed, error: {:?}", vm_status,)
                        },
                    };
                }
                if OLVM::should_restart_execution(output_ext.txn_output()) {
                    info!(log_context, "Reconfiguration occurred: restart required",);
                    ExecutionStatus::SkipRest(OLTransactionOutput::new(output_ext))
                } else {
                    ExecutionStatus::Success(OLTransactionOutput::new(output_ext))
                }
            },
            Err(err) => ExecutionStatus::Abort(err),
        }
    }
}