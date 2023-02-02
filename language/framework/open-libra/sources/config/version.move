/// Maintains the version number for the blockchain.
module open_libra::version {
    use std::error;
    use std::signer;

    use open_libra::reconfiguration;
    use open_libra::system_addresses;

    friend open_libra::genesis;

    struct Version has key {
        major: u64,
    }

    struct SetVersionCapability has key {}

    /// Specified major version number must be greater than current version number.
    const EINVALID_MAJOR_VERSION_NUMBER: u64 = 1;
    /// Account is not authorized to make this change.
    const ENOT_AUTHORIZED: u64 = 2;

    /// Only called during genesis.
    /// Publishes the Version config.
    public(friend) fun initialize(open_libra: &signer, initial_version: u64) {
        system_addresses::assert_open_libra(open_libra);

        move_to(open_libra, Version { major: initial_version });
        // Give open libra account capability to call set version. This allows on chain governance to
	// do it through control of the open libra account.
        move_to(open_libra, SetVersionCapability {});
    }

    /// Updates the major version to a larger version.
    /// This can be called by on chain governance.
    public entry fun set_version(account: &signer, major: u64) acquires Version {
        assert!(exists<SetVersionCapability>(signer::address_of(account)), error::permission_denied(ENOT_AUTHORIZED));

        let old_major = *&borrow_global<Version>(@open_libra).major;
        assert!(old_major < major, error::invalid_argument(EINVALID_MAJOR_VERSION_NUMBER));

        let config = borrow_global_mut<Version>(@open_libra);
        config.major = major;

        // Need to trigger reconfiguration so validator nodes can sync on the updated version.
        reconfiguration::reconfigure();
    }

    /// Only called in tests and testnets. This allows the core resources account, which only exists in tests/testnets,
    /// to update the version.
    fun initialize_for_test(core_resources: &signer) {
        system_addresses::assert_core_resource(core_resources);
        move_to(core_resources, SetVersionCapability {});
    }

    #[test(open_libra = @open_libra)]
    public entry fun test_set_version(open_libra: signer) acquires Version {
        initialize(&open_libra, 1);
        assert!(borrow_global<Version>(@open_libra).major == 1, 0);
        set_version(&open_libra, 2);
        assert!(borrow_global<Version>(@open_libra).major == 2, 1);
    }

    #[test(open_libra = @open_libra, core_resources = @core_resources)]
    public entry fun test_set_version_core_resources(
        open_libra: signer,
        core_resources: signer,
    ) acquires Version {
        initialize(&open_libra, 1);
        assert!(borrow_global<Version>(@open_libra).major == 1, 0);
        initialize_for_test(&core_resources);
        set_version(&core_resources, 2);
        assert!(borrow_global<Version>(@open_libra).major == 2, 1);
    }

    #[test(open_libra = @open_libra, random_account = @0x123)]
    #[expected_failure(abort_code = 327682, location = Self)]
    public entry fun test_set_version_unauthorized_should_fail(
        open_libra: signer,
        random_account: signer,
    ) acquires Version {
        initialize(&open_libra, 1);
        set_version(&random_account, 2);
    }
}
