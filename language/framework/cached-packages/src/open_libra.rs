// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

#![allow(unused_imports)]

pub use crate::open_libra_transaction_builder::*;
use ol_types::{account_address::AccountAddress, transaction::TransactionPayload};

pub fn ol_coin_transfer(to: AccountAddress, amount: u64) -> TransactionPayload {
    coin_transfer(
        ol_types::ol_coin::OL_COIN_TYPE.clone(),
        to,
        amount,
    )
}
