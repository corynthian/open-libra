/// The chain id distinguishes between different chains (e.g., testnet and the main network).
/// One important role is to prevent transactions intended for one chain from being executed on another.
/// This code provides a container for storing a chain id and functions to initialize and get it.
module open_libra::chain_id {
    use open_libra::system_addresses;

    friend open_libra::genesis;

    struct ChainId has key {
        id: u8
    }

    /// Only called during genesis.
    /// Publish the chain ID `id` of this instance under the SystemAddresses address
    public(friend) fun initialize(open_libra: &signer, id: u8) {
        system_addresses::assert_open_libra(open_libra);
        move_to(open_libra, ChainId { id })
    }

    /// Return the chain ID of this instance.
    public fun get(): u8 acquires ChainId {
        borrow_global<ChainId>(@open_libra).id
    }

    #[test_only]
    public fun initialize_for_test(open_libra: &signer, id: u8) {
        initialize(open_libra, id);
    }

    #[test(open_libra = @0x1)]
    fun test_get(open_libra: &signer) acquires ChainId {
        initialize_for_test(open_libra, 1u8);
        assert!(get() == 1u8, 1);
    }
}
