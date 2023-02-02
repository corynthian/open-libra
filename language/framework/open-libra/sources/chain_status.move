/// This module code to assert that it is running in genesis (`Self::assert_genesis`) or after
/// genesis (`Self::assert_operating`). These are essentially distinct states of the system. Specifically,
/// if `Self::assert_operating` succeeds, assumptions about invariants over the global state can be made
/// which reflect that the system has been successfully initialized.
module open_libra::chain_status {
    use open_libra::system_addresses;
    use std::error;

    friend open_libra::genesis;

    /// Marker to publish at the end of genesis.
    struct GenesisEndMarker has key {}

    /// The blockchain is not in the operating status.
    const ENOT_OPERATING: u64 = 1;
    /// The blockchain is not in the genesis status.
    const ENOT_GENESIS: u64 = 2;

    /// Marks that genesis has finished.
    public(friend) fun set_genesis_end(open_libra: &signer) {
        system_addresses::assert_open_libra(open_libra);
        move_to(open_libra, GenesisEndMarker {});
    }

    /// Helper function to determine if 0L is in genesis state.
    public fun is_genesis(): bool {
        !exists<GenesisEndMarker>(@open_libra)
    }

    /// Helper function to determine if 0L is operating. This is
    /// the same as `!is_genesis()` and is provided for convenience.
    /// Testing `is_operating()` is more frequent than `is_genesis()`.
    public fun is_operating(): bool {
        exists<GenesisEndMarker>(@open_libra)
    }

    /// Helper function to assert operating (not genesis) state.
    public fun assert_operating() {
        assert!(is_operating(), error::invalid_state(ENOT_OPERATING));
    }

    /// Helper function to assert genesis state.
    public fun assert_genesis() {
        assert!(is_genesis(), error::invalid_state(ENOT_OPERATING));
    }
}
