// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

use crate::delta_change_set::{addition, deserialize, subtraction};
use ol_types::vm_status::StatusCode;
use move_binary_format::errors::{PartialVMError, PartialVMResult};
use move_core_types::account_address::AccountAddress;
use move_table_extension::{TableHandle, TableResolver};
use std::collections::{BTreeMap, BTreeSet};

/// Describes the state of each aggregator instance.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AggregatorState {
    // If aggregator stores a known value.
    Data,
    // If aggregator stores a non-negative delta.
    PositiveDelta,
    // If aggregator stores a negative delta.
    NegativeDelta,
}

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct AggregatorHandle(pub AccountAddress);

/// Uniquely identifies each aggregator instance in storage.
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct AggregatorID {
    // A handle that is shared accross all aggregator instances created by the
    // same `AggregatorFactory` and which is used for fine-grained storage
    // access.
    pub handle: TableHandle,
    // Unique key associated with each aggregator instance. Generated by
    // taking the hash of transaction which creates an aggregator and the
    // number of aggregators that were created by this transaction so far.
    pub key: AggregatorHandle,
}

impl AggregatorID {
    pub fn new(handle: TableHandle, key: AggregatorHandle) -> Self {
        AggregatorID { handle, key }
    }
}

/// Tracks values seen by aggregator. In particular, stores information about
/// the biggest and the smallest deltas seen during execution in the VM. This
/// information can be used by the executor to check if delta should have
/// failed. Most importantly, it allows commutativity of adds/subs. Example:
///
///
/// This graph shows how delta of aggregator changed during a single transaction
/// execution:
///
/// +A ===========================================>
///            ||
///          ||||                               +X
///         |||||  ||||||                    ||||
///      |||||||||||||||||||||||||          |||||
/// +0 ===========================================> time
///                       ||||||
///                         ||
///                         ||
/// -B ===========================================>
///
/// Clearly, +X succeeds if +A and -B succeed. Therefore each delta
/// validation consists of:
///   1. check +A did not overflow
///   2. check -A did not drop below zero
/// Checking +X is irrelevant since +A >= +X.
///
/// TODO: while we support tracking of the history, it is not yet fully used on
/// executor side because we don't know how to throw errors.
#[derive(Debug)]
pub struct History {
    pub max_positive: u128,
    pub min_negative: u128,
}

impl History {
    fn new() -> Self {
        History {
            max_positive: 0,
            min_negative: 0,
        }
    }

    fn record_positive(&mut self, value: u128) {
        self.max_positive = u128::max(self.max_positive, value);
    }

    fn record_negative(&mut self, value: u128) {
        self.min_negative = u128::max(self.min_negative, value);
    }
}

/// Internal aggregator data structure.
pub struct Aggregator {
    // Describes a value of an aggregator.
    value: u128,
    // Describes a state of an aggregator.
    state: AggregatorState,
    // Describes an upper bound of an aggregator. If `value` exceeds it, the
    // aggregator overflows.
    // TODO: Currently this is a single u128 value since we use 0 as a trivial
    // lower bound. If we want to support custom lower bounds, or have more
    // complex postconditions, we should factor this out in its own struct.
    limit: u128,
    // Describes values seen by this aggregator. Note that if aggregator knows
    // its value, then storing history doesn't make sense.
    history: Option<History>,
}

impl Aggregator {
    /// Records observed delta in history. Should be called after an operation
    /// to record its side-effects.
    fn record(&mut self) {
        if let Some(history) = self.history.as_mut() {
            match self.state {
                AggregatorState::PositiveDelta => history.record_positive(self.value),
                AggregatorState::NegativeDelta => history.record_negative(self.value),
                AggregatorState::Data => {
                    unreachable!("history is not tracked when aggregator knows its value")
                },
            }
        }
    }

    /// Implements logic for adding to an aggregator.
    pub fn add(&mut self, value: u128) -> PartialVMResult<()> {
        match self.state {
            AggregatorState::Data => {
                // If aggregator knows the value, add directly and keep the state.
                self.value = addition(self.value, value, self.limit)?;
                return Ok(());
            },
            AggregatorState::PositiveDelta => {
                // If positive delta, add directly but also record the state.
                self.value = addition(self.value, value, self.limit)?;
            },
            AggregatorState::NegativeDelta => {
                // Negative delta is a special case, since the state might
                // change depending on how big the `value` is. Suppose
                // aggregator has -X and want to do +Y. Then, there are two
                // cases:
                //     1. X <= Y: then the result is +(Y-X)
                //     2. X  > Y: then the result is -(X-Y)
                if self.value <= value {
                    self.value = subtraction(value, self.value)?;
                    self.state = AggregatorState::PositiveDelta;
                } else {
                    self.value = subtraction(self.value, value)?;
                }
            },
        }

        // Record side-effects of addition in history.
        self.record();
        Ok(())
    }

    /// Implements logic for subtracting from an aggregator.
    pub fn sub(&mut self, value: u128) -> PartialVMResult<()> {
        match self.state {
            AggregatorState::Data => {
                // Aggregator knows the value, therefore we can subtract
                // checking we don't drop below zero. We do not need to
                // record the history.
                self.value = subtraction(self.value, value)?;
                return Ok(());
            },
            AggregatorState::PositiveDelta => {
                // Positive delta is a special case because the state can
                // change depending on how big the `value` is. Suppose
                // aggregator has +X and want to do -Y. Then, there are two
                // cases:
                //     1. X >= Y: then the result is +(X-Y)
                //     2. X  < Y: then the result is -(Y-X)
                if self.value >= value {
                    self.value = subtraction(self.value, value)?;
                } else {
                    // Check that we can subtract in general: we don't want to
                    // allow -10000 when limit is 10.
                    // TODO: maybe `subtraction` should also know about the limit?
                    subtraction(self.limit, value)?;

                    self.value = subtraction(value, self.value)?;
                    self.state = AggregatorState::NegativeDelta;
                }
            },
            AggregatorState::NegativeDelta => {
                // Since we operate on unsigned integers, we have to add
                // when subtracting from negative delta. Note that if limit
                // is some X, then we cannot subtract more than X, and so
                // we should return an error there.
                self.value = addition(self.value, value, self.limit)?;
            },
        }

        // Record side-effects of addition in history.
        self.record();
        Ok(())
    }

    /// Implements logic for reading the value of an aggregator. As a
    /// result, the aggregator knows it value (i.e. its state changes to
    /// `Data`).
    pub fn read_and_materialize(
        &mut self,
        resolver: &dyn TableResolver,
        id: &AggregatorID,
    ) -> PartialVMResult<u128> {
        // If aggregator has already been read, return immediately.
        if self.state == AggregatorState::Data {
            return Ok(self.value);
        }

        // Otherwise, we have a delta and have to go to storage and apply it.
        // In theory, any delta will be applied to existing value. However,
        // something may go wrong, so we guard by throwing an error in
        // extension.
        let key_bytes = id.key.0.to_vec();
        resolver
            .resolve_table_entry(&id.handle, &key_bytes)
            .map_err(|_| extension_error("could not find the value of the aggregator"))?
            .map_or(
                Err(extension_error(
                    "could not find the value of the aggregator",
                )),
                |bytes| {
                    // Get the value from the storage to which we want to apply
                    // the delta.
                    let value_from_storage = deserialize(&bytes);

                    // Sanity checks.
                    debug_assert!(
                        self.history.is_some(),
                        "resolving aggregator with no history"
                    );
                    let history = self.history.as_ref().unwrap();

                    // Validate history of the aggregator, ensure that there
                    // was no violation of postcondition. We can do it by
                    // emulating addition and subtraction.
                    addition(value_from_storage, history.max_positive, self.limit)?;
                    subtraction(value_from_storage, history.min_negative)?;

                    // Validation succeeded, and now we can actually apply the delta.
                    match self.state {
                        AggregatorState::PositiveDelta => {
                            self.value = addition(value_from_storage, self.value, self.limit)?;
                        },
                        AggregatorState::NegativeDelta => {
                            self.value = subtraction(value_from_storage, self.value)?;
                        },
                        AggregatorState::Data => {
                            unreachable!("history is not tracked when aggregator knows its value")
                        },
                    }

                    // Change the state and return the new value. Also, make
                    // sure history is no longer tracked.
                    self.state = AggregatorState::Data;
                    self.history = None;
                    Ok(self.value)
                },
            )
    }

    /// Unpacks aggregator into its fields.
    pub fn into(self) -> (u128, AggregatorState, u128, Option<History>) {
        (self.value, self.state, self.limit, self.history)
    }
}

/// Stores all information about aggregators (how many have been created or
/// removed), what are their states, etc. per single transaction).
#[derive(Default)]
pub struct AggregatorData {
    // All aggregators that were created in the current transaction, stored as ids.
    // Used to filter out aggregators that were created and destroyed in the
    // within a single transaction.
    new_aggregators: BTreeSet<AggregatorID>,
    // All aggregators that were destroyed in the current transaction, stored as ids.
    destroyed_aggregators: BTreeSet<AggregatorID>,
    // All aggregator instances that exist in the current transaction.
    aggregators: BTreeMap<AggregatorID, Aggregator>,
}

impl AggregatorData {
    /// Returns a mutable reference to an aggregator with `id` and a `limit`.
    /// If transaction that is currently executing did not initilize it), a new
    /// aggregator instance is created, with a zero-initialized value and in a
    /// delta state.
    /// Note: when we say "aggregator instance" here we refer to Rust struct and
    /// not to the Move aggregator.
    pub fn get_aggregator(&mut self, id: AggregatorID, limit: u128) -> &mut Aggregator {
        self.aggregators.entry(id).or_insert_with(|| Aggregator {
            value: 0,
            state: AggregatorState::PositiveDelta,
            limit,
            history: Some(History::new()),
        });
        self.aggregators.get_mut(&id).unwrap()
    }

    /// Returns the number of aggregators that are used in the current transaction.
    pub fn num_aggregators(&self) -> u128 {
        self.aggregators.len() as u128
    }

    /// Creates and a new Aggregator with a given `id` and a `limit`. The value
    /// of a new aggregator is always known, therefore it is created in a data
    /// state, with a zero-initialized value.
    pub fn create_new_aggregator(&mut self, id: AggregatorID, limit: u128) {
        let aggregator = Aggregator {
            value: 0,
            state: AggregatorState::Data,
            limit,
            history: None,
        };
        self.aggregators.insert(id, aggregator);
        self.new_aggregators.insert(id);
    }

    /// If aggregator has been used in this transaction, it is removed. Otherwise,
    /// it is marked for deletion.
    pub fn remove_aggregator(&mut self, id: AggregatorID) {
        // Aggregator no longer in use during this transaction: remove it.
        self.aggregators.remove(&id);

        if self.new_aggregators.contains(&id) {
            // Aggregator has been created in the same transaction. Therefore, no
            // side-effects.
            self.new_aggregators.remove(&id);
        } else {
            // Otherwise, aggregator has been created somewhere else.
            self.destroyed_aggregators.insert(id);
        }
    }

    /// Unpacks aggregator data.
    pub fn into(
        self,
    ) -> (
        BTreeSet<AggregatorID>,
        BTreeSet<AggregatorID>,
        BTreeMap<AggregatorID, Aggregator>,
    ) {
        (
            self.new_aggregators,
            self.destroyed_aggregators,
            self.aggregators,
        )
    }
}

/// Returns partial VM error on extension failure.
pub fn extension_error(message: impl ToString) -> PartialVMError {
    PartialVMError::new(StatusCode::VM_EXTENSION_ERROR).with_message(message.to_string())
}

// ================================= Tests =================================

#[cfg(test)]
mod test {
    use super::*;
    use crate::delta_change_set::serialize;
    use ol_state_view::TStateView;
    use ol_types::{
        account_address::AccountAddress,
        state_store::{
            state_key::StateKey, state_storage_usage::StateStorageUsage,
            table::TableHandle as OLTableHandle,
        },
    };
    use claims::{assert_err, assert_ok};
    use once_cell::sync::Lazy;
    use std::collections::HashMap;

    #[derive(Default)]
    pub struct FakeTestStorage {
        data: HashMap<StateKey, Vec<u8>>,
    }

    impl FakeTestStorage {
        fn new() -> Self {
            let mut data = HashMap::new();

            // Initialize storage with some test data.
            data.insert(id_to_state_key(test_id(600)), serialize(&300));
            FakeTestStorage { data }
        }
    }

    impl TStateView for FakeTestStorage {
        type Key = StateKey;

        fn get_state_value(&self, state_key: &StateKey) -> anyhow::Result<Option<Vec<u8>>> {
            Ok(self.data.get(state_key).cloned())
        }

        fn is_genesis(&self) -> bool {
            self.data.is_empty()
        }

        fn get_usage(&self) -> anyhow::Result<StateStorageUsage> {
            Ok(StateStorageUsage::new_untracked())
        }
    }

    impl TableResolver for FakeTestStorage {
        fn resolve_table_entry(
            &self,
            handle: &TableHandle,
            key: &[u8],
        ) -> Result<Option<Vec<u8>>, anyhow::Error> {
            let state_key = StateKey::table_item(OLTableHandle::from(*handle), key.to_vec());
            self.get_state_value(&state_key)
        }
    }

    fn test_id(key: u128) -> AggregatorID {
        let bytes: Vec<u8> = [key.to_le_bytes(), key.to_le_bytes()]
            .iter()
            .flat_map(|b| b.to_vec())
            .collect();
        let key = AggregatorHandle(AccountAddress::from_bytes(bytes).unwrap());
        AggregatorID::new(TableHandle(AccountAddress::ZERO), key)
    }

    fn id_to_state_key(id: AggregatorID) -> StateKey {
        StateKey::table_item(OLTableHandle::from(id.handle), id.key.0.to_vec())
    }

    #[allow(clippy::redundant_closure)]
    static TEST_RESOLVER: Lazy<FakeTestStorage> = Lazy::new(|| FakeTestStorage::new());

    #[test]
    fn test_materialize_not_in_storage() {
        let mut aggregator_data = AggregatorData::default();

        let aggregator = aggregator_data.get_aggregator(test_id(300), 700);
        assert_err!(aggregator.read_and_materialize(&*TEST_RESOLVER, &test_id(700)));
    }

    #[test]
    fn test_materialize_known() {
        let mut aggregator_data = AggregatorData::default();
        aggregator_data.create_new_aggregator(test_id(200), 200);

        let aggregator = aggregator_data.get_aggregator(test_id(200), 200);
        assert_ok!(aggregator.add(100));
        assert_ok!(aggregator.read_and_materialize(&*TEST_RESOLVER, &test_id(200)));
        assert_eq!(aggregator.value, 100);
    }

    #[test]
    fn test_materialize_overflow() {
        let mut aggregator_data = AggregatorData::default();

        // +0 to +400 satisfies <= 600 and is ok, but materialization fails
        // with 300 + 400 > 600!
        let aggregator = aggregator_data.get_aggregator(test_id(600), 600);
        assert_ok!(aggregator.add(400));
        assert_err!(aggregator.read_and_materialize(&*TEST_RESOLVER, &test_id(600)));
    }

    #[test]
    fn test_materialize_underflow() {
        let mut aggregator_data = AggregatorData::default();

        // +0 to -400 is ok, but materialization fails with 300 - 400 < 0!
        let aggregator = aggregator_data.get_aggregator(test_id(600), 600);
        assert_ok!(aggregator.add(400));
        assert_err!(aggregator.read_and_materialize(&*TEST_RESOLVER, &test_id(600)));
    }

    #[test]
    fn test_materialize_non_monotonic_1() {
        let mut aggregator_data = AggregatorData::default();

        // +0 to +400 to +0 is ok, but materialization fails since we had 300 + 400 > 600!
        let aggregator = aggregator_data.get_aggregator(test_id(600), 600);
        assert_ok!(aggregator.add(400));
        assert_ok!(aggregator.sub(300));
        assert_eq!(aggregator.value, 100);
        assert_eq!(aggregator.state, AggregatorState::PositiveDelta);
        assert_err!(aggregator.read_and_materialize(&*TEST_RESOLVER, &test_id(600)));
    }

    #[test]
    fn test_materialize_non_monotonic_2() {
        let mut aggregator_data = AggregatorData::default();

        // +0 to -301 to -300 is ok, but materialization fails since we had 300 - 301 < 0!
        let aggregator = aggregator_data.get_aggregator(test_id(600), 600);
        assert_ok!(aggregator.sub(301));
        assert_ok!(aggregator.add(1));
        assert_eq!(aggregator.value, 300);
        assert_eq!(aggregator.state, AggregatorState::NegativeDelta);
        assert_err!(aggregator.read_and_materialize(&*TEST_RESOLVER, &test_id(600)));
    }

    #[test]
    fn test_add_overflow() {
        let mut aggregator_data = AggregatorData::default();

        // +0 to +800 > 600!
        let aggregator = aggregator_data.get_aggregator(test_id(600), 600);
        assert_err!(aggregator.add(800));

        // 0 + 300 > 200!
        let aggregator = aggregator_data.get_aggregator(test_id(200), 200);
        assert_err!(aggregator.add(300));
    }

    #[test]
    fn test_sub_underflow() {
        let mut aggregator_data = AggregatorData::default();
        aggregator_data.create_new_aggregator(test_id(200), 200);

        // +0 to -601 is impossible!
        let aggregator = aggregator_data.get_aggregator(test_id(600), 600);
        assert_err!(aggregator.sub(601));

        // Similarly, we cannot subtract anything from 0...
        let aggregator = aggregator_data.get_aggregator(test_id(200), 200);
        assert_err!(aggregator.sub(2));
    }

    #[test]
    fn test_commutative() {
        let mut aggregator_data = AggregatorData::default();

        // +200 -300 +50 +300 -25 +375 -600.
        let aggregator = aggregator_data.get_aggregator(test_id(600), 600);
        assert_ok!(aggregator.add(200));
        assert_ok!(aggregator.sub(300));

        assert_eq!(aggregator.value, 100);
        assert_eq!(aggregator.history.as_ref().unwrap().max_positive, 200);
        assert_eq!(aggregator.history.as_ref().unwrap().min_negative, 100);
        assert_eq!(aggregator.state, AggregatorState::NegativeDelta);

        assert_ok!(aggregator.add(50));
        assert_ok!(aggregator.add(300));
        assert_ok!(aggregator.sub(25));

        assert_eq!(aggregator.value, 225);
        assert_eq!(aggregator.history.as_ref().unwrap().max_positive, 250);
        assert_eq!(aggregator.history.as_ref().unwrap().min_negative, 100);
        assert_eq!(aggregator.state, AggregatorState::PositiveDelta);

        assert_ok!(aggregator.add(375));
        assert_ok!(aggregator.sub(600));

        assert_eq!(aggregator.value, 0);
        assert_eq!(aggregator.history.as_ref().unwrap().max_positive, 600);
        assert_eq!(aggregator.history.as_ref().unwrap().min_negative, 100);
        assert_eq!(aggregator.state, AggregatorState::PositiveDelta);
    }
}