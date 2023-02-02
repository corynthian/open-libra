spec open_libra::gas_schedule {
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict;
    }

    spec initialize(open_libra: &signer, gas_schedule_blob: vector<u8>) {
        use std::signer;

        include system_addresses::AbortsIfNotOpenLibra{ account: open_libra };
        aborts_if len(gas_schedule_blob) == 0;
        aborts_if exists<GasScheduleV2>(signer::address_of(open_libra));
        ensures exists<GasScheduleV2>(signer::address_of(open_libra));
    }

    spec set_gas_schedule(open_libra: &signer, gas_schedule_blob: vector<u8>) {
        use std::signer;
        use open_libra::util;
	// 0L-TODO
        // use open_libra::stake;
        use open_libra::coin::CoinInfo;
        use open_libra::ol_coin::OLCoin;

        // requires exists<stake::ValidatorFees>(@open_libra);
        requires exists<CoinInfo<OLCoin>>(@open_libra);

        include system_addresses::AbortsIfNotOpenLibra{ account: open_libra };
        aborts_if len(gas_schedule_blob) == 0;
        let new_gas_schedule = util::spec_from_bytes<GasScheduleV2>(gas_schedule_blob);
        let gas_schedule = global<GasScheduleV2>(@open_libra);
        aborts_if exists<GasScheduleV2>(@open_libra) && new_gas_schedule.feature_version < gas_schedule.feature_version;
        ensures exists<GasScheduleV2>(signer::address_of(open_libra));
    }

    spec set_storage_gas_config(open_libra: &signer, config: StorageGasConfig) {
	// 0L-TODO
        // use open_libra::stake;
        use open_libra::coin::CoinInfo;
        use open_libra::ol_coin::OLCoin;

        // requires exists<stake::ValidatorFees>(@open_libra);
        requires exists<CoinInfo<OLCoin>>(@open_libra);

        include system_addresses::AbortsIfNotOpenLibra{ account: open_libra };
        aborts_if !exists<StorageGasConfig>(@open_libra);
    }
}
