spec open_libra::state_storage {
    spec module {
        use std::chain_status;
        pragma verify = true;
        pragma aborts_if_is_strict;
        // After genesis, `StateStorageUsage` and `GasParameter` exist.
        invariant [suspendable] chain_status::is_operating() ==> exists<StateStorageUsage>(@open_libra);
        invariant [suspendable] chain_status::is_operating() ==> exists<GasParameter>(@open_libra);
    }

    /// ensure caller is admin.
    /// aborts if StateStorageUsage already exists.
    spec initialize(open_libra: &signer) {
        use std::signer;
        let addr = signer::address_of(open_libra);
        aborts_if !system_addresses::is_open_libra_address(addr);
        aborts_if exists<StateStorageUsage>(@open_libra);
    }

    spec on_new_block(epoch: u64) {
        use std::chain_status;
        requires chain_status::is_operating();
        aborts_if false;
    }

    spec current_items_and_bytes(): (u64, u64) {
        aborts_if !exists<StateStorageUsage>(@open_libra);
    }

    spec get_state_storage_usage_only_at_epoch_beginning(): Usage {
        // TODO: temporary mockup.
        pragma opaque;
    }

    spec on_reconfig {
        aborts_if true;
    }
}
