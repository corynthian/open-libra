// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

use ol_crypto::ValidCryptoMaterialStringExt;
use ol_keygen::KeyGen;
use ol_types::transaction::authenticator::AuthenticationKey;

fn main() {
    let mut keygen = KeyGen::from_os_rng();
    let (privkey, pubkey) = keygen.generate_ed25519_keypair();

    println!("Private Key:");
    println!("{}", privkey.to_encoded_string().unwrap());

    println!();

    let auth_key = AuthenticationKey::ed25519(&pubkey);
    let account_addr = auth_key.derived_address();

    println!("Auth Key:");
    println!("{}", auth_key.to_encoded_string().unwrap());
    println!();

    println!("Account Address:");
    println!("{}", account_addr);
    println!();
}
