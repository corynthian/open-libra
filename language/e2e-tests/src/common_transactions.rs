// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

//! Support for encoding transactions for common situations.

use crate::account::Account;
use ol_cached_packages::open_libra;
use ol_types::transaction::{Script, SignedTransaction};
use move_ir_compiler::Compiler;
use once_cell::sync::Lazy;

pub static EMPTY_SCRIPT: Lazy<Vec<u8>> = Lazy::new(|| {
    let code = "
    main(account: signer) {
    label b0:
      return;
    }
";
    let modules = ol_cached_packages::head_release_bundle().compiled_modules();
    let compiler = Compiler {
        deps: modules.iter().collect(),
    };
    compiler.into_script_blob(code).expect("Failed to compile")
});

pub fn empty_txn(
    sender: &Account,
    seq_num: u64,
    max_gas_amount: u64,
    gas_unit_price: u64,
) -> SignedTransaction {
    sender
        .transaction()
        .script(Script::new(EMPTY_SCRIPT.to_vec(), vec![], vec![]))
        .sequence_number(seq_num)
        .max_gas_amount(max_gas_amount)
        .gas_unit_price(gas_unit_price)
        .sign()
}

/// Returns a transaction to create a new account with the given arguments.
pub fn create_account_txn(
    sender: &Account,
    new_account: &Account,
    seq_num: u64,
) -> SignedTransaction {
    sender
        .transaction()
        .payload(open_libra::ol_account_create_account(
            *new_account.address(),
        ))
        .sequence_number(seq_num)
        .sign()
}

/// Returns a transaction to transfer coin from one account to another (possibly new) one, with the
/// given arguments.
pub fn peer_to_peer_txn(
    sender: &Account,
    receiver: &Account,
    seq_num: u64,
    transfer_amount: u64,
) -> SignedTransaction {
    // get a SignedTransaction
    sender
        .transaction()
        .payload(open_libra::ol_coin_transfer(
            *receiver.address(),
            transfer_amount,
        ))
        .sequence_number(seq_num)
        .sign()
}
