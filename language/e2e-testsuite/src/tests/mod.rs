// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

//! Test module.
//!
//! Add new test modules to this list.
//!
//! This is not in a top-level tests directory because each file there gets compiled into a
//! separate binary. The linker ends up repeating a lot of work for each binary to not much
//! benefit.
//!
//! Set env REGENERATE_GOLDENFILES to update the golden files when running tests..

// works: mod account_universe;
// works: mod create_account;
// works: mod data_store;
// works: mod execution_strategies;
// works: mod failed_transaction_tests;
// works: mod genesis;
// works: mod genesis_initializations;
// works: mod mint;
// works: mod module_publishing;
mod on_chain_configs;
// works: mod peer_to_peer;
// works: mod scripts;
// works: mod transaction_fuzzer;
// works: mod verify_txn;
