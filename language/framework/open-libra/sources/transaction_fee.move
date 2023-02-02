/// This module provides an interface to burn or collect and redistribute transaction fees.
module open_libra::transaction_fee {
    use open_libra::coin::{Self, AggregatableCoin, BurnCapability, Coin};
    use open_libra::ol_coin::OLCoin;
    use open_libra::validator;
    use open_libra::system_addresses;
    use std::error;
    use std::option::{Self, Option};

    friend open_libra::block;
    friend open_libra::genesis;
    friend open_libra::reconfiguration;
    friend open_libra::transaction_validation;

    /// Gas fees are already being collected and the struct holding
    /// information about collected amounts is already published.
    const EALREADY_COLLECTING_FEES: u64 = 1;

    /// The burn percentage is out of range [0, 100].
    const EINVALID_BURN_PERCENTAGE: u64 = 3;

    /// Stores burn capability to burn the gas fees.
    struct OLCoinCapabilities has key {
        burn_cap: BurnCapability<OLCoin>,
    }

    /// Stores information about the block proposer and the amount of fees
    /// collected when executing the block.
    struct CollectedFeesPerBlock has key {
        amount: AggregatableCoin<OLCoin>,
        proposer: Option<address>,
        burn_percentage: u8,
    }

    /// Initializes the resource storing information about gas fees collection and
    /// distribution. Should be called by on-chain governance.
    public fun initialize_fee_collection_and_distribution(open_libra: &signer, burn_percentage: u8) {
        system_addresses::assert_open_libra(open_libra);
        assert!(
            !exists<CollectedFeesPerBlock>(@open_libra),
            error::already_exists(EALREADY_COLLECTING_FEES)
        );
        assert!(burn_percentage <= 100, error::out_of_range(EINVALID_BURN_PERCENTAGE));

	// 0L-TODO: Commented out fee collection
        // Make sure stakng module is aware of transaction fees collection.
        // stake::initialize_validator_fees(open_libra);

        // Initially, no fees are collected and the block proposer is not set.
        let collected_fees = CollectedFeesPerBlock {
            amount: coin::initialize_aggregatable_coin(open_libra),
            proposer: option::none(),
            burn_percentage,
        };
        move_to(open_libra, collected_fees);
    }

    fun is_fees_collection_enabled(): bool {
        exists<CollectedFeesPerBlock>(@open_libra)
    }

    /// Sets the burn percentage for collected fees to a new value. Should be called by on-chain governance.
    public fun upgrade_burn_percentage(
        open_libra: &signer,
        new_burn_percentage: u8
    ) acquires OLCoinCapabilities, CollectedFeesPerBlock {
        system_addresses::assert_open_libra(open_libra);
        assert!(new_burn_percentage <= 100, error::out_of_range(EINVALID_BURN_PERCENTAGE));

        // Prior to upgrading the burn percentage, make sure to process collected
        // fees. Otherwise we would use the new (incorrect) burn_percentage when
        // processing fees later!
        process_collected_fees();

        if (is_fees_collection_enabled()) {
            // Upgrade has no effect unless fees are being collected.
            let burn_percentage = &mut borrow_global_mut<CollectedFeesPerBlock>(@open_libra).burn_percentage;
            *burn_percentage = new_burn_percentage
        }
    }

    /// Registers the proposer of the block for gas fees collection. This function
    /// can only be called at the beginning of the block.
    public(friend) fun register_proposer_for_fee_collection(proposer_addr: address) acquires CollectedFeesPerBlock {
        if (is_fees_collection_enabled()) {
            let collected_fees = borrow_global_mut<CollectedFeesPerBlock>(@open_libra);
            let _ = option::swap_or_fill(&mut collected_fees.proposer, proposer_addr);
        }
    }

    /// Burns a specified fraction of the coin.
    fun burn_coin_fraction(coin: &mut Coin<OLCoin>, burn_percentage: u8) acquires OLCoinCapabilities {
        assert!(burn_percentage <= 100, error::out_of_range(EINVALID_BURN_PERCENTAGE));

        let collected_amount = coin::value(coin);
        spec {
            // We assume that `burn_percentage * collected_amount` does not overflow.
            assume burn_percentage * collected_amount <= MAX_U64;
        };
        let amount_to_burn = (burn_percentage as u64) * collected_amount / 100;
        if (amount_to_burn > 0) {
            let coin_to_burn = coin::extract(coin, amount_to_burn);
            coin::burn(
                coin_to_burn,
                &borrow_global<OLCoinCapabilities>(@open_libra).burn_cap,
            );
        }
    }

    /// Calculates the fee which should be distributed to the block proposer at the
    /// end of an epoch, and records it in the system. This function can only be called
    /// at the beginning of the block or during reconfiguration.
    public(friend) fun process_collected_fees() acquires OLCoinCapabilities, CollectedFeesPerBlock {
        if (!is_fees_collection_enabled()) {
            return
        };
        let collected_fees = borrow_global_mut<CollectedFeesPerBlock>(@open_libra);

        // If there are no collected fees, only unset the proposer. See the rationale for
        // setting proposer to option::none() below.
        if (coin::is_aggregatable_coin_zero(&collected_fees.amount)) {
            if (option::is_some(&collected_fees.proposer)) {
                let _ = option::extract(&mut collected_fees.proposer);
            };
            return
        };

        // Otherwise get the collected fee, and check if it can distributed later.
        let coin = coin::drain_aggregatable_coin(&mut collected_fees.amount);
        if (option::is_some(&collected_fees.proposer)) {
            // Extract the address of proposer here and reset it to option::none(). This
            // is particularly useful to avoid any undesired side-effects where coins are
            // collected but never distributed or distributed to the wrong account.
            // With this design, processing collected fees enforces that all fees will be burnt
            // unless the proposer is specified in the block prologue. When we have a governance
            // proposal that triggers reconfiguration, we distribute pending fees and burn the
            // fee for the proposal. Otherwise, that fee would be leaked to the next block.
            let proposer = option::extract(&mut collected_fees.proposer);

            // Since the block can be produced by the VM itself, we have to make sure we catch
            // this case.
            if (proposer == @vm_reserved) {
                burn_coin_fraction(&mut coin, 100);
                coin::destroy_zero(coin);
                return
            };

            burn_coin_fraction(&mut coin, collected_fees.burn_percentage);
	    // 0L-TODO: Investigate fees
            validator::add_transaction_fee(proposer, coin);
            return
        };

        // If checks did not pass, simply burn all collected coins and return none.
        burn_coin_fraction(&mut coin, 100);
        coin::destroy_zero(coin)
    }

    /// Burn transaction fees in epilogue.
    public(friend) fun burn_fee(account: address, fee: u64) acquires OLCoinCapabilities {
        coin::burn_from<OLCoin>(
            account,
            fee,
            &borrow_global<OLCoinCapabilities>(@open_libra).burn_cap,
        );
    }

    /// Collect transaction fees in epilogue.
    public(friend) fun collect_fee(account: address, fee: u64) acquires CollectedFeesPerBlock {
        let collected_fees = borrow_global_mut<CollectedFeesPerBlock>(@open_libra);

        // Here, we are always optimistic and always collect fees. If the proposer is not set,
        // or we cannot redistribute fees later for some reason (e.g. account cannot receive AptoCoin)
        // we burn them all at once. This way we avoid having a check for every transaction epilogue.
        let collected_amount = &mut collected_fees.amount;
        coin::collect_into_aggregatable_coin<OLCoin>(account, fee, collected_amount);
    }

    /// Only called during genesis.
    public(friend) fun store_ol_coin_burn_cap(open_libra: &signer, burn_cap: BurnCapability<OLCoin>) {
        system_addresses::assert_open_libra(open_libra);
        move_to(open_libra, OLCoinCapabilities { burn_cap })
    }

    #[test_only]
    use open_libra::aggregator_factory;

    #[test(open_libra = @open_libra)]
    fun test_initialize_fee_collection_and_distribution(open_libra: signer) acquires CollectedFeesPerBlock {
        aggregator_factory::initialize_aggregator_factory_for_test(&open_libra);
        initialize_fee_collection_and_distribution(&open_libra, 25);

        // Check struct has been published.
        assert!(exists<CollectedFeesPerBlock>(@open_libra), 0);

        // Check that initial balance is 0 and there is no proposer set.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@open_libra);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(option::is_none(&collected_fees.proposer), 0);
        assert!(collected_fees.burn_percentage == 25, 0);
    }

    #[test(open_libra = @open_libra)]
    fun test_burn_fraction_calculation(open_libra: signer) acquires OLCoinCapabilities {
        use open_libra::ol_coin;
        let (burn_cap, mint_cap) = ol_coin::initialize_for_test(&open_libra);
        store_ol_coin_burn_cap(&open_libra, burn_cap);

        let c1 = coin::mint<OLCoin>(100, &mint_cap);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 100, 0);

        // Burning 25%.
        burn_coin_fraction(&mut c1, 25);
        assert!(coin::value(&c1) == 75, 0);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 75, 0);

        // Burning 0%.
        burn_coin_fraction(&mut c1, 0);
        assert!(coin::value(&c1) == 75, 0);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 75, 0);

        // Burning remaining 100%.
        burn_coin_fraction(&mut c1, 100);
        assert!(coin::value(&c1) == 0, 0);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 0, 0);

        coin::destroy_zero(c1);
        let c2 = coin::mint<OLCoin>(10, &mint_cap);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 10, 0);

        burn_coin_fraction(&mut c2, 5);
        assert!(coin::value(&c2) == 10, 0);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 10, 0);

        burn_coin_fraction(&mut c2, 100);
        coin::destroy_zero(c2);
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(open_libra = @open_libra, alice = @0xa11ce, bob = @0xb0b, carol = @0xca101)]
    fun test_fees_distribution(
        open_libra: signer,
        alice: signer,
        bob: signer,
        carol: signer,
    ) acquires OLCoinCapabilities, CollectedFeesPerBlock {
        use std::signer;
        use open_libra::ol_account;
        use open_libra::ol_coin;

        // Initialization.
        let (burn_cap, mint_cap) = ol_coin::initialize_for_test(&open_libra);
        store_ol_coin_burn_cap(&open_libra, burn_cap);
        initialize_fee_collection_and_distribution(&open_libra, 10);

        // Create dummy accounts.
        let alice_addr = signer::address_of(&alice);
        let bob_addr = signer::address_of(&bob);
        let carol_addr = signer::address_of(&carol);
        ol_account::create_account(alice_addr);
        ol_account::create_account(bob_addr);
        ol_account::create_account(carol_addr);
        coin::deposit(alice_addr, coin::mint(10000, &mint_cap));
        coin::deposit(bob_addr, coin::mint(10000, &mint_cap));
        coin::deposit(carol_addr, coin::mint(10000, &mint_cap));
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 30000, 0);

        // Block 1 starts.
        process_collected_fees();
        register_proposer_for_fee_collection(alice_addr);

        // Check that there was no fees distribution in the first block.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@open_libra);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(*option::borrow(&collected_fees.proposer) == alice_addr, 0);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 30000, 0);

        // Simulate transaction fee collection - here we simply collect some fees from Bob.
        collect_fee(bob_addr, 100);
        collect_fee(bob_addr, 500);
        collect_fee(bob_addr, 400);

        // Now Bob must have 1000 less in his account. Alice and Carol have the same amounts.
        assert!(coin::balance<OLCoin>(alice_addr) == 10000, 0);
        assert!(coin::balance<OLCoin>(bob_addr) == 9000, 0);
        assert!(coin::balance<OLCoin>(carol_addr) == 10000, 0);

        // Block 2 starts.
        process_collected_fees();
        register_proposer_for_fee_collection(bob_addr);

        // Collected fees from Bob must have been assigned to Alice.
        assert!(stake::get_validator_fee(alice_addr) == 900, 0);
        assert!(coin::balance<OLCoin>(alice_addr) == 10000, 0);
        assert!(coin::balance<OLCoin>(bob_addr) == 9000, 0);
        assert!(coin::balance<OLCoin>(carol_addr) == 10000, 0);

        // Also, aggregator coin is drained and total supply is slightly changed (10% of 1000 is burnt).
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@open_libra);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(*option::borrow(&collected_fees.proposer) == bob_addr, 0);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 29900, 0);

        // Simulate transaction fee collection one more time.
        collect_fee(bob_addr, 5000);
        collect_fee(bob_addr, 4000);

        assert!(coin::balance<OLCoin>(alice_addr) == 10000, 0);
        assert!(coin::balance<OLCoin>(bob_addr) == 0, 0);
        assert!(coin::balance<OLCoin>(carol_addr) == 10000, 0);

        // Block 3 starts.
        process_collected_fees();
        register_proposer_for_fee_collection(carol_addr);

        // Collected fees should have been assigned to Bob because he was the peoposer.
        assert!(stake::get_validator_fee(alice_addr) == 900, 0);
        assert!(coin::balance<OLCoin>(alice_addr) == 10000, 0);
        assert!(stake::get_validator_fee(bob_addr) == 8100, 0);
        assert!(coin::balance<OLCoin>(bob_addr) == 0, 0);
        assert!(coin::balance<OLCoin>(carol_addr) == 10000, 0);

        // Again, aggregator coin is drained and total supply is changed by 10% of 9000.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@open_libra);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(*option::borrow(&collected_fees.proposer) == carol_addr, 0);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 29000, 0);

        // Simulate transaction fee collection one last time.
        collect_fee(alice_addr, 1000);
        collect_fee(alice_addr, 1000);

        // Block 4 starts.
        process_collected_fees();
        register_proposer_for_fee_collection(alice_addr);

        // Check that 2000 was collected from Alice.
        assert!(coin::balance<OLCoin>(alice_addr) == 8000, 0);
        assert!(coin::balance<OLCoin>(bob_addr) == 0, 0);

        // Carol must have some fees assigned now.
        let collected_fees = borrow_global<CollectedFeesPerBlock>(@open_libra);
        assert!(stake::get_validator_fee(carol_addr) == 1800, 0);
        assert!(coin::is_aggregatable_coin_zero(&collected_fees.amount), 0);
        assert!(*option::borrow(&collected_fees.proposer) == alice_addr, 0);
        assert!(*option::borrow(&coin::supply<OLCoin>()) == 28800, 0);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}
