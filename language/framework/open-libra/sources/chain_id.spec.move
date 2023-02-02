spec open_libra::chain_id {
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict;
    }

    spec initialize {
        use std::signer;
        let addr = signer::address_of(open_libra);
        aborts_if addr != @open_libra;
        aborts_if exists<ChainId>(@open_libra);
    }

    spec get {
        aborts_if !exists<ChainId>(@open_libra);
    }
}
