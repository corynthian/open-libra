spec open_libra::ol_coin {
    spec module {
        pragma verify = true;
        pragma aborts_if_is_strict;
    }

    spec initialize {
        pragma aborts_if_is_partial;
        let addr = signer::address_of(open_libra);
        ensures exists<MintCapStore>(addr);
        ensures exists<coin::CoinInfo<OLCoin>>(addr);
    }

    spec destroy_mint_cap {
        let addr = signer::address_of(open_libra);
        aborts_if addr != @open_libra;
        aborts_if !exists<MintCapStore>(@open_libra);
    }

    // Test function,not needed verify.
    spec configure_accounts_for_test {
        pragma verify = false;
    }

    // Only callable in tests and testnets.not needed verify.
    spec mint {
        pragma verify = false;
    }

    // Only callable in tests and testnets.not needed verify.
    spec delegate_mint_capability {
        pragma verify = false;
    }

    // Only callable in tests and testnets.not needed verify.
    spec claim_mint_capability(account: &signer) {
        pragma verify = false;
    }

    spec find_delegation(addr: address): Option<u64> {
        aborts_if !exists<Delegations>(@core_resources);
    }
}
