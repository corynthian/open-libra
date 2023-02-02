/**
 * Validator life-cycle:
 * 1. Prepares node setup procedure by calling `validator::initialize_validator`.
 */
module open_libra::validator {
    use std::error;
    // use std::features;
    use std::option::Self; // , Option};
    // use std::signer;
    use std::vector;
    use std::bls12381;
    // use std::math64::min;
    use std::table::{Self, Table};
    use open_libra::ol_coin::OLCoin;
    // use open_libra::account;
    use open_libra::coin::{Self, Coin, MintCapability};
    // use open_libra::event::{Self, EventHandle};
    // use open_libra::timestamp;
    use open_libra::system_addresses;
    // use open_libra::tower_config::{Self, StakingConfig};
    // use open_libra::chain_status;

    use std::bls12381::proof_of_possession_from_bytes;

    friend open_libra::block;
    friend open_libra::genesis;
    friend open_libra::reconfiguration;
    friend open_libra::transaction_fee;

    /// Validator Config not published.
    const EVALIDATOR_CONFIG: u64 = 1;
    /// The verifiable delay proof is invalid.
    const EINVALID_PROOF: u64 = 2;
    /// Account is already a validator or pending validator.
    const EALREADY_ACTIVE_VALIDATOR: u64 = 3;
    /// Account is not a validator.
    const ENOT_VALIDATOR: u64 = 4;
    /// Can't remove last validator.
    const ELAST_VALIDATOR: u64 = 5;
    /// Account is already registered as a validator candidate.
    const EALREADY_REGISTERED: u64 = 6;
    /// Account does not have the right operator capability.
    const ENOT_OPERATOR: u64 = 7;
    /// Validators cannot join or leave post genesis on this test network.
    const ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED: u64 = 8;
    /// Invalid consensus public key
    const EINVALID_PUBLIC_KEY: u64 = 9;
    /// Validator set exceeds the limit
    const EVALIDATOR_SET_TOO_LARGE: u64 = 10;
    /// Voting power increase has exceeded the limit for this current epoch.
    const EVOTING_POWER_INCREASE_EXCEEDS_LIMIT: u64 = 11;
    /// Owner capability does not exist at the provided account.
    const EOWNER_CAP_NOT_FOUND: u64 = 12;
    /// An account cannot own more than one owner capability.
    const EOWNER_CAP_ALREADY_EXISTS: u64 = 13;
    /// Validator is not defined in the ACL of entities allowed to be validators.
    const EINELIGIBLE_VALIDATOR: u64 = 14;
    /// Table to store collected transaction fees for each validator already exists.
    const EFEES_TABLE_ALREADY_EXISTS: u64 = 15;

    /// Validator status enum. We can switch to proper enum later once Move supports it.
    const VALIDATOR_STATUS_PENDING_ACTIVE: u64 = 1;
    const VALIDATOR_STATUS_ACTIVE: u64 = 2;
    const VALIDATOR_STATUS_PENDING_INACTIVE: u64 = 3;
    const VALIDATOR_STATUS_INACTIVE: u64 = 4;

    /// Limit the maximum size to u16::max (the current limit of a `bitvec`).
    const MAX_VALIDATOR_SET_SIZE: u64 = 65536;

    /// Limit the maximum value of `rewards_rate` in order to avoid any arithmetic overflow.
    const MAX_REWARDS_RATE: u64 = 1000000;

    /// Capability that represents ownership and can be used to control the validator and the associated
    /// stake pool. Having this be separate from the signer for the account that the validator resources
    /// are hosted at allows modules to have control over a validator.
    struct OwnerCapability has key, store {
        pool_address: address,
    }

    // 0L-TODO: Tower

    /// Validator info stored in validator address.
    struct ValidatorConfig has key, copy, store, drop {
        consensus_pubkey: vector<u8>,
        network_addresses: vector<u8>,
        fullnode_addresses: vector<u8>,
        // Index in the active set if the validator corresponding to this stake pool is active.
        validator_index: u64,
    }

    /// Consensus information per validator, stored in ValidatorSet.
    struct ValidatorInfo has copy, store, drop {
        addr: address,
        voting_power: u64,
        config: ValidatorConfig,
    }
    
    /// Full ValidatorSet, stored at @open_libra.
    /// 1. `join_validator_set` adds to `pending_active` queue.
    /// 2. `leave_validator_set` moves from active to `pending_inactive` queue.
    /// 3. `on_new_epoch` processes two pending queues and refresh ValidatorInfo from the owners
    ///     address.
    struct ValidatorSet has key {
        consensus_scheme: u8,
        // Active validators for the current epoch.
        active_validators: vector<ValidatorInfo>,
        // Pending validators to leave in next epoch (still active).
        pending_inactive: vector<ValidatorInfo>,
        // Pending validators to join in next epoch.
        pending_active: vector<ValidatorInfo>,
        // Current total voting power.
        total_voting_power: u128,
        // Total voting power waiting to join in the next epoch.
        total_joining_power: u128,
    }
    
    /// OLCoin capabilities, set during genesis and stored in @CoreResource account.
    /// This allows the `validator` module to mint rewards to stakers.
    struct OLCoinCapabilities has key {
        mint_cap: MintCapability<OLCoin>,
    }
    
    struct IndividualValidatorPerformance has store, drop {
        successful_proposals: u64,
        failed_proposals: u64,
    }
    
    struct ValidatorPerformance has key {
        validators: vector<IndividualValidatorPerformance>,
    }

    // 0L-TODO
    // struct RegisterValidatorCandidateEvent has drop, store { proof: _ }

    struct SetOperatorEvent has drop, store {
	// 0L-TODO: proof: _,
	old_operator: address,
	new_operator: address,
    }

    struct AddTowerEvent has drop, store {
	// 0L-TODO: proof: _,
	tower_height_added: u64,
    }

    struct ReactivateTowerEvent has drop, store {
	// 0L-TODO: proof: _,
	tower_height: u64,
    }

    struct RotateConsensusKeyEvent has drop, store {
	// 0L-TODO: proof: _,
        old_consensus_pubkey: vector<u8>,
        new_consensus_pubkey: vector<u8>,
    }
    
    struct UpdateNetworkAndFullnodeAddressesEvent has drop, store {
	// 0L-TODO: proof: _, 
        old_network_addresses: vector<u8>,
        new_network_addresses: vector<u8>,
        old_fullnode_addresses: vector<u8>,
        new_fullnode_addresses: vector<u8>,
    }

    // 0L-TODO: struct JoinValidatorSetEvent has drop, store { proof: _ }

    struct DistributeRewardsEvent has drop, store {
	rewards_amount: u64,
    }

    // 0L-TODO: struct LeaveValidatorSetEvent has drop, store { .. }

    /// Stores transaction fees assigned to validators. All fees are distributed to validators
    /// at the end of the epoch.
    struct ValidatorFees has key {
        fees_table: Table<address, Coin<OLCoin>>,
    }

    /// Initializes the resource storing information about collected transaction fees per validator.
    /// Used by `transaction_fee.move` to initialize fee collection and distribution.
    public(friend) fun initialize_validator_fees(open_libra: &signer) {
        system_addresses::assert_open_libra(open_libra);
        assert!(
            !exists<ValidatorFees>(@open_libra),
            error::already_exists(EFEES_TABLE_ALREADY_EXISTS)
        );
        move_to(open_libra, ValidatorFees { fees_table: table::new() });
    }

    /// Stores the transaction fee collected to the specified validator address.
    public(friend) fun add_transaction_fee(validator_addr: address, fee: Coin<OLCoin>) acquires ValidatorFees {
        let fees_table = &mut borrow_global_mut<ValidatorFees>(@open_libra).fees_table;
        if (table::contains(fees_table, validator_addr)) {
            let collected_fee = table::borrow_mut(fees_table, validator_addr);
            coin::merge(collected_fee, fee);
        } else {
            table::add(fees_table, validator_addr, fee);
        }
    }
    
    // 0L-TODO: get_tower_weight()

    // 0L-TODO: get_validator_state(): u64

    // 0L-TODO: get_current_epoch_voting_power(): u64

    // 0L-TODO: get_delegated_voter()

    // 0L-TODO: get_operator()

    // 0L-TODO: get_validator_index()

    public(friend) fun initialize(open_libra: &signer) {
	system_addresses::assert_open_libra(open_libra);

        move_to(open_libra, ValidatorSet {
            consensus_scheme: 0,
            active_validators: vector::empty(),
            pending_active: vector::empty(),
            pending_inactive: vector::empty(),
            total_voting_power: 0,
            total_joining_power: 0,
        });

        move_to(open_libra, ValidatorPerformance {
            validators: vector::empty(),
        });
    }

    /// This is only called during Genesis, which is where MintCapability<OLCoin> can be created.
    /// Beyond genesis, no one can create OLCoin mint/burn capabilities.
    public(friend) fun store_ol_coin_mint_cap(open_libra: &signer, mint_cap: MintCapability<OLCoin>) {
        system_addresses::assert_open_libra(open_libra);
        move_to(open_libra, OLCoinCapabilities { mint_cap })
    }
    
    // Remove validators from the validator set
    // 0L-TODO: remove_validators(open_libra, validators) acquires ValidatorSet

    /// Initialize the validator account and give ownership to the signing account.
    public entry fun initialize_validator(
        account: &signer,
        consensus_pubkey: vector<u8>,
        proof_of_possession: vector<u8>,
        network_addresses: vector<u8>,
        fullnode_addresses: vector<u8>,
    ) { //acquires AllowedValidators {
        // Checks the public key has a valid proof-of-possession to prevent rogue-key attacks.
        let pubkey_from_pop = &mut bls12381::public_key_from_bytes_with_pop(
            consensus_pubkey,
            &proof_of_possession_from_bytes(proof_of_possession)
        );
        assert!(option::is_some(pubkey_from_pop), error::invalid_argument(EINVALID_PUBLIC_KEY));

	// 0L-TODO: initialize_owner(account);

        move_to(account, ValidatorConfig {
            consensus_pubkey,
            network_addresses,
            fullnode_addresses,
            validator_index: 0,
        });
    }
}
