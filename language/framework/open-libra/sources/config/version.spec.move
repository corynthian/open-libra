spec open_libra::version {
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict;
    }

    spec set_version(account: &signer, major: u64) {
        use std::signer;
        use open_libra::chain_status;
        use open_libra::timestamp;
	// 0L-TODO
        // use open_libra::stake;
        use open_libra::coin::CoinInfo;
        use open_libra::ol_coin::OLCoin;

        requires chain_status::is_operating();
        requires timestamp::spec_now_microseconds() >= reconfiguration::last_reconfiguration_time();
	// 0L-TODO
        // requires exists<stake::ValidatorFees>(@open_libra);
        requires exists<CoinInfo<OLCoin>>(@open_libra);

        aborts_if !exists<SetVersionCapability>(signer::address_of(account));
        aborts_if !exists<Version>(@open_libra);

        let old_major = global<Version>(@open_libra).major;
        aborts_if !(old_major < major);
    }

    /// Abort if resource already exists in `@open_libra` when initializing.
    spec initialize(open_libra: &signer, initial_version: u64) {
        use std::signer;

        aborts_if signer::address_of(open_libra) != @open_libra;
        aborts_if exists<Version>(@open_libra);
        aborts_if exists<SetVersionCapability>(@open_libra);
    }

    /// This module turns on `aborts_if_is_strict`, so need to add spec for test function
    /// `initialize_for_test`.
    spec initialize_for_test {
        // Don't verify test functions.
        pragma verify = false;
    }
}
