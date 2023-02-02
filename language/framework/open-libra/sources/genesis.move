module open_libra::genesis {
    use std::error;
    // use std::fixed_point32;
    use std::vector;
    // use std::simple_map;

    use open_libra::account;
    use open_libra::aggregator_factory;
    use open_libra::ol_coin::{Self, OLCoin};
    // use open_libra::ol_governance;
    use open_libra::block;
    use open_libra::chain_id;
    use open_libra::chain_status;
    use open_libra::coin;
    use open_libra::consensus_config;
    use open_libra::create_signer::create_signer;
    use open_libra::gas_schedule;
    use open_libra::reconfiguration;
    // use open_libra::stake;
    // use open_libra::staking_contract;
    // use open_libra::staking_config;
    use open_libra::state_storage;
    use open_libra::storage_gas;
    use open_libra::timestamp;
    use open_libra::transaction_fee;
    use open_libra::transaction_validation;
    use open_libra::version;
    // use open_libra::vesting;

    const EDUPLICATE_ACCOUNT: u64 = 1;
    const EACCOUNT_DOES_NOT_EXIST: u64 = 2;

    struct AccountMap has drop {
        account_address: address,
        balance: u64,
    }

    struct EmployeeAccountMap has copy, drop {
        accounts: vector<address>,
        validator: ValidatorConfigurationWithCommission,
        vesting_schedule_numerator: vector<u64>,
        vesting_schedule_denominator: u64,
        beneficiary_resetter: address,
    }

    struct ValidatorConfiguration has copy, drop {
        owner_address: address,
        operator_address: address,
        voter_address: address,
        stake_amount: u64,
        consensus_pubkey: vector<u8>,
        proof_of_possession: vector<u8>,
        network_addresses: vector<u8>,
        full_node_network_addresses: vector<u8>,
    }

    struct ValidatorConfigurationWithCommission has copy, drop {
        validator_config: ValidatorConfiguration,
        commission_percentage: u64,
        join_during_genesis: bool,
    }

    /// Genesis step 1: Initialize ol framework account and core modules on chain.
    fun initialize(
        gas_schedule: vector<u8>,
        chain_id: u8,
        initial_version: u64,
        consensus_config: vector<u8>,
        epoch_interval_microsecs: u64,
        _minimum_stake: u64,
        _maximum_stake: u64,
        _recurring_lockup_duration_secs: u64,
        _allow_validator_set_change: bool,
        _rewards_rate: u64,
        _rewards_rate_denominator: u64,
        _voting_power_increase_limit: u64,
    ) {
        // Initialize the ol framework account. This is the account where system resources and modules will be
        // deployed to. This will be entirely managed by on-chain governance and no entities have the key or privileges
        // to use this account.
        let (open_libra, _ol_signer_cap) = account::create_framework_reserved_account(@open_libra);
        // Initialize account configs on ol framework account.
        account::initialize(&open_libra);

        transaction_validation::initialize(
            &open_libra,
            b"script_prologue",
            b"module_prologue",
            b"multi_agent_script_prologue",
            b"epilogue",
        );

        // Give the decentralized on-chain governance control over the core framework account.
        // governance::store_signer_cap(&open_libra, @open_libra, open_libra_signer_cap);

        // put reserved framework reserved accounts under ol governance
        // let framework_reserved_addresses = vector<address>[@0x2, @0x3, @0x4, @0x5, @0x6, @0x7, @0x8, @0x9, @0xa];
        // while (!vector::is_empty(&framework_reserved_addresses)) {
        //     let address = vector::pop_back<address>(&mut framework_reserved_addresses);
        //     let (open_libra, framework_signer_cap) = account::create_framework_reserved_account(address);
        //     governance::store_signer_cap(&open_libra, address, framework_signer_cap);
        // };

        consensus_config::initialize(&open_libra, consensus_config);
        version::initialize(&open_libra, initial_version);

	// 0L-TODO
        // stake::initialize(&open_libra);
        // staking_config::initialize(
        //     &open_libra,
        //     minimum_stake,
        //     maximum_stake,
        //     recurring_lockup_duration_secs,
        //     allow_validator_set_change,
        //     rewards_rate,
        //     rewards_rate_denominator,
        //     voting_power_increase_limit,
        // );

        storage_gas::initialize(&open_libra);
        gas_schedule::initialize(&open_libra, gas_schedule);

        // Ensure we can create aggregators for supply, but not enable it for common use just yet.
        aggregator_factory::initialize_aggregator_factory(&open_libra);
        coin::initialize_supply_config(&open_libra);

        chain_id::initialize(&open_libra, chain_id);
        reconfiguration::initialize(&open_libra);
        block::initialize(&open_libra, epoch_interval_microsecs);
        state_storage::initialize(&open_libra);
        timestamp::set_time_has_started(&open_libra);
    }

    // Genesis step 2: Initialize OL coin.
    // fun initialize_ol_coin(open_libra: &signer) {
    //     let (burn_cap, _mint_cap) = ol_coin::initialize(open_libra);
    // 	// 0L-TODO
    //     // Give stake module MintCapability<OLCoin> so it can mint rewards.
    //     // stake::store_ol_coin_mint_cap(open_libra, mint_cap);
    //     // Give transaction_fee module BurnCapability<OLCoin> so it can burn gas.
    //     transaction_fee::store_ol_coin_burn_cap(open_libra, burn_cap);
    // }

    /// Only called for testnets and e2e tests.
    fun initialize_core_resources_and_ol_coin(
        open_libra: &signer,
        core_resources_auth_key: vector<u8>,
    ) {
        let (burn_cap, mint_cap) = ol_coin::initialize(open_libra);
	// 0L-TODO
        // Give stake module MintCapability<OLCoin> so it can mint rewards.
        // stake::store_ol_coin_mint_cap(open_libra, mint_cap);
        // Give transaction_fee module BurnCapability<OLCoin> so it can burn gas.
        transaction_fee::store_ol_coin_burn_cap(open_libra, burn_cap);

        let core_resources = account::create_account(@core_resources);
        account::rotate_authentication_key_internal(&core_resources, core_resources_auth_key);
        ol_coin::configure_accounts_for_test(open_libra, &core_resources, mint_cap);
    }

    fun create_accounts(open_libra: &signer, accounts: vector<AccountMap>) {
        let i = 0;
        let num_accounts = vector::length(&accounts);
        let unique_accounts = vector::empty();

        while (i < num_accounts) {
            let account_map = vector::borrow(&accounts, i);
            assert!(
                !vector::contains(&unique_accounts, &account_map.account_address),
                error::already_exists(EDUPLICATE_ACCOUNT),
            );
            vector::push_back(&mut unique_accounts, account_map.account_address);

            create_account(
                open_libra,
                account_map.account_address,
                account_map.balance,
            );

            i = i + 1;
        };
    }

    /// This creates an funds an account if it doesn't exist.
    /// If it exists, it just returns the signer.
    fun create_account(open_libra: &signer, account_address: address, balance: u64): signer {
        if (account::exists_at(account_address)) {
            create_signer(account_address)
        } else {
            let account = account::create_account(account_address);
            coin::register<OLCoin>(&account);
            ol_coin::mint(open_libra, account_address, balance);
            account
        }
    }

    // 0L-TODO
    // fun create_employee_validators(
    //     employee_vesting_start: u64,
    //     employee_vesting_period_duration: u64,
    //     employees: vector<EmployeeAccountMap>,
    // ) {
    //     let i = 0;
    //     let num_employee_groups = vector::length(&employees);
    //     let unique_accounts = vector::empty();

    //     while (i < num_employee_groups) {
    //         let j = 0;
    //         let employee_group = vector::borrow(&employees, i);
    //         let num_employees_in_group = vector::length(&employee_group.accounts);

    //         let buy_ins = simple_map::create();

    //         while (j < num_employees_in_group) {
    //             let account = vector::borrow(&employee_group.accounts, j);
    //             assert!(
    //                 !vector::contains(&unique_accounts, account),
    //                 error::already_exists(EDUPLICATE_ACCOUNT),
    //             );
    //             vector::push_back(&mut unique_accounts, *account);

    //             let employee = create_signer(*account);
    //             let total = coin::balance<OLCoin>(*account);
    //             let coins = coin::withdraw<OLCoin>(&employee, total);
    //             simple_map::add(&mut buy_ins, *account, coins);

    //             j = j + 1;
    //         };

    //         let j = 0;
    //         let num_vesting_events = vector::length(&employee_group.vesting_schedule_numerator);
    //         let schedule = vector::empty();

    //         while (j < num_vesting_events) {
    //             let numerator = vector::borrow(&employee_group.vesting_schedule_numerator, j);
    //             let event = fixed_point32::create_from_rational(*numerator, employee_group.vesting_schedule_denominator);
    //             vector::push_back(&mut schedule, event);

    //             j = j + 1;
    //         };

    //         let vesting_schedule = vesting::create_vesting_schedule(
    //             schedule,
    //             employee_vesting_start,
    //             employee_vesting_period_duration,
    //         );

    //         let admin = employee_group.validator.validator_config.owner_address;
    //         let admin_signer = &create_signer(admin);
    //         let contract_address = vesting::create_vesting_contract(
    //             admin_signer,
    //             &employee_group.accounts,
    //             buy_ins,
    //             vesting_schedule,
    //             admin,
    //             employee_group.validator.validator_config.operator_address,
    //             employee_group.validator.validator_config.voter_address,
    //             employee_group.validator.commission_percentage,
    //             x"",
    //         );
    //         let pool_address = vesting::stake_pool_address(contract_address);

    //         if (employee_group.beneficiary_resetter != @0x0) {
    //             vesting::set_beneficiary_resetter(admin_signer, contract_address, employee_group.beneficiary_resetter);
    //         };

    //         let validator = &employee_group.validator.validator_config;
    //         assert!(
    //             account::exists_at(validator.owner_address),
    //             error::not_found(EACCOUNT_DOES_NOT_EXIST),
    //         );
    //         assert!(
    //             account::exists_at(validator.operator_address),
    //             error::not_found(EACCOUNT_DOES_NOT_EXIST),
    //         );
    //         assert!(
    //             account::exists_at(validator.voter_address),
    //             error::not_found(EACCOUNT_DOES_NOT_EXIST),
    //         );
    //         if (employee_group.validator.join_during_genesis) {
    //             initialize_validator(pool_address, validator);
    //         };

    //         i = i + 1;
    //     }
    // }

    fun create_initialize_validators_with_commission(
        open_libra: &signer,
        use_staking_contract: bool,
        validators: vector<ValidatorConfigurationWithCommission>,
    ) {
        let i = 0;
        let num_validators = vector::length(&validators);
        while (i < num_validators) {
            let validator = vector::borrow(&validators, i);
            create_initialize_validator(open_libra, validator, use_staking_contract);

            i = i + 1;
        };

        // Destroy the ol framework account's ability to mint coins now that we're done with setting up the initial
        // validators.
        ol_coin::destroy_mint_cap(open_libra);

	// 0L-TODO
        // stake::on_new_epoch();
    }

    /// Sets up the initial validator set for the network.
    /// The validator "owner" accounts, and their authentication
    /// Addresses (and keys) are encoded in the `owners`
    /// Each validator signs consensus messages with the private key corresponding to the Ed25519
    /// public key in `consensus_pubkeys`.
    /// Finally, each validator must specify the network address
    /// (see types/src/network_address/mod.rs) for itself and its full nodes.
    ///
    /// Network address fields are a vector per account, where each entry is a vector of addresses
    /// encoded in a single BCS byte array.
    fun create_initialize_validators(open_libra: &signer, validators: vector<ValidatorConfiguration>) {
        let i = 0;
        let num_validators = vector::length(&validators);

        let validators_with_commission = vector::empty();

        while (i < num_validators) {
            let validator_with_commission = ValidatorConfigurationWithCommission {
                validator_config: vector::pop_back(&mut validators),
                commission_percentage: 0,
                join_during_genesis: true,
            };
            vector::push_back(&mut validators_with_commission, validator_with_commission);

            i = i + 1;
        };

        create_initialize_validators_with_commission(open_libra, false, validators_with_commission);
    }

    fun create_initialize_validator(
        open_libra: &signer,
        commission_config: &ValidatorConfigurationWithCommission,
        _use_staking_contract: bool,
    ) {
        let validator = &commission_config.validator_config;

        let _owner = &create_account(open_libra, validator.owner_address, validator.stake_amount);
        create_account(open_libra, validator.operator_address, 0);
        create_account(open_libra, validator.voter_address, 0);

	// 0L-TODO
        // Initialize the stake pool and join the validator set.
        // let pool_address = if (use_staking_contract) {
        //     staking_contract::create_staking_contract(
        //         owner,
        //         validator.operator_address,
        //         validator.voter_address,
        //         validator.stake_amount,
        //         commission_config.commission_percentage,
        //         x"",
        //     );
        //     staking_contract::stake_pool_address(validator.owner_address, validator.operator_address)
        // } else {
        //     stake::initialize_stake_owner(
        //         owner,
        //         validator.stake_amount,
        //         validator.operator_address,
        //         validator.voter_address,
        //     );
        //     validator.owner_address
        // };

        // if (commission_config.join_during_genesis) {
        //     initialize_validator(pool_address, validator);
        // };
    }

    fun initialize_validator(_pool_address: address, validator: &ValidatorConfiguration) {
        let _operator = &create_signer(validator.operator_address);

	// 0L-TODO
        // stake::rotate_consensus_key(
        //     operator,
        //     pool_address,
        //     validator.consensus_pubkey,
        //     validator.proof_of_possession,
        // );
        // stake::update_network_and_fullnode_addresses(
        //     operator,
        //     pool_address,
        //     validator.network_addresses,
        //     validator.full_node_network_addresses,
        // );
        // stake::join_validator_set_internal(operator, pool_address);
    }

    /// The last step of genesis.
    fun set_genesis_end(open_libra: &signer) {
        chain_status::set_genesis_end(open_libra);
    }

    #[verify_only]
    use std::features;

    #[verify_only]
    fun initialize_for_verification(
        gas_schedule: vector<u8>,
        chain_id: u8,
        initial_version: u64,
        consensus_config: vector<u8>,
        epoch_interval_microsecs: u64,
        minimum_stake: u64,
        maximum_stake: u64,
        recurring_lockup_duration_secs: u64,
        allow_validator_set_change: bool,
        rewards_rate: u64,
        rewards_rate_denominator: u64,
        voting_power_increase_limit: u64,
        open_libra: &signer,
        _min_voting_threshold: u128,
        _required_proposer_stake: u64,
        _voting_duration_secs: u64,
        accounts: vector<AccountMap>,
        _employee_vesting_start: u64,
        _employee_vesting_period_duration: u64,
        _employees: vector<EmployeeAccountMap>,
        validators: vector<ValidatorConfigurationWithCommission>
    ) {
        initialize(
            gas_schedule,
            chain_id,
            initial_version,
            consensus_config,
            epoch_interval_microsecs,
            minimum_stake,
            maximum_stake,
            recurring_lockup_duration_secs,
            allow_validator_set_change,
            rewards_rate,
            rewards_rate_denominator,
            voting_power_increase_limit
        );
        features::change_feature_flags(open_libra, vector[1, 2], vector[]);
        // initialize_ol_coin(open_libra);
        // governance::initialize_for_verification(
        //     open_libra,
        //     min_voting_threshold,
        //     required_proposer_stake,
        //     voting_duration_secs
        // );
        create_accounts(open_libra, accounts);
        // create_employee_validators(employee_vesting_start, employee_vesting_period_duration, employees);
        create_initialize_validators_with_commission(open_libra, true, validators);
        set_genesis_end(open_libra);
    }

    #[test_only]
    public fun setup() {
        initialize(
            x"000000000000000000", // empty gas schedule
            4u8, // TESTING chain ID
            0,
            x"12",
            1,
            0,
            1,
            1,
            true,
            1,
            1,
            30,
        )
    }

    #[test]
    fun test_setup() {
        setup();
        assert!(account::exists_at(@open_libra), 1);
        assert!(account::exists_at(@0x2), 1);
        assert!(account::exists_at(@0x3), 1);
        assert!(account::exists_at(@0x4), 1);
        assert!(account::exists_at(@0x5), 1);
        assert!(account::exists_at(@0x6), 1);
        assert!(account::exists_at(@0x7), 1);
        assert!(account::exists_at(@0x8), 1);
        assert!(account::exists_at(@0x9), 1);
        assert!(account::exists_at(@0xa), 1);
    }

    #[test(open_libra = @0x1)]
    fun test_create_account(open_libra: &signer) {
        setup();
        initialize_ol_coin(open_libra);

        let addr = @0x121341; // 01 -> 0a are taken
        let test_signer_before = create_account(open_libra, addr, 15);
        let test_signer_after = create_account(open_libra, addr, 500);
        assert!(test_signer_before == test_signer_after, 0);
        assert!(coin::balance<OLCoin>(addr) == 15, 1);
    }

    #[test(open_libra = @0x1)]
    fun test_create_accounts(open_libra: &signer) {
        setup();
        initialize_ol_coin(open_libra);

        // 01 -> 0a are taken
        let addr0 = @0x121341;
        let addr1 = @0x121345;

        let accounts = vector[
            AccountMap {
                account_address: addr0,
                balance: 12345,
            },
            AccountMap {
                account_address: addr1,
                balance: 67890,
            },
        ];

        create_accounts(open_libra, accounts);
        assert!(coin::balance<OLCoin>(addr0) == 12345, 0);
        assert!(coin::balance<OLCoin>(addr1) == 67890, 1);

        create_account(open_libra, addr0, 23456);
        assert!(coin::balance<OLCoin>(addr0) == 12345, 2);
    }
}
