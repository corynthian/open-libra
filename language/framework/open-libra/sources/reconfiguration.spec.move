spec open_libra::reconfiguration {
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict;

        // After genesis, `Configuration` exists.
        invariant [suspendable] chain_status::is_operating() ==> exists<Configuration>(@open_libra);
        invariant [suspendable] chain_status::is_operating() ==>
            (timestamp::spec_now_microseconds() >= last_reconfiguration_time());
    }

    /// Make sure the signer address is @open_libra.
    spec schema AbortsIfNotOpenLibra {
        open_libra: &signer;

        let addr = signer::address_of(open_libra);
        aborts_if !system_addresses::is_open_libra_address(addr);
    }

    /// Address @open_libra must exist resource Account and Configuration.
    /// Already exists in framework account.
    /// Guid_creation_num should be 2 according to logic.
    spec initialize(open_libra: &signer) {
        use std::signer;
        use open_libra::account::{Account};

        include AbortsIfNotOpenLibra;
        let addr = signer::address_of(open_libra);
        requires exists<Account>(addr);
        aborts_if !(global<Account>(addr).guid_creation_num == 2);
        aborts_if exists<Configuration>(@open_libra);
    }

    spec current_epoch(): u64 {
        aborts_if !exists<Configuration>(@open_libra);
    }

    spec disable_reconfiguration(open_libra: &signer) {
        include AbortsIfNotOpenLibra;
        aborts_if exists<DisableReconfiguration>(@open_libra);
    }

    /// Make sure the caller is admin and check the resource DisableReconfiguration.
    spec enable_reconfiguration(open_libra: &signer) {
        use open_libra::reconfiguration::{DisableReconfiguration};
        include AbortsIfNotOpenLibra;
        aborts_if !exists<DisableReconfiguration>(@open_libra);
    }

    /// When genesis_event emit the epoch and the `last_reconfiguration_time` .
    /// Should equal to 0
    spec emit_genesis_reconfiguration_event {
        use open_libra::reconfiguration::{Configuration};

        aborts_if !exists<Configuration>(@open_libra);
        let config_ref = global<Configuration>(@open_libra);
        aborts_if !(config_ref.epoch == 0 && config_ref.last_reconfiguration_time == 0);
    }

    spec last_reconfiguration_time {
        aborts_if !exists<Configuration>(@open_libra);
    }

    spec reconfigure {
        use open_libra::coin::CoinInfo;
        use open_libra::ol_coin::OLCoin;

	// 0L-TODO
        // requires exists<stake::ValidatorFees>(@open_libra);
        requires exists<CoinInfo<OLCoin>>(@open_libra);

        aborts_if false;
    }
}
