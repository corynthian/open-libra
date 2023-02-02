// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

use vdf::{PietrzakVDFParams, InvalidProof};
use once_cell::sync::Lazy;

/// The length of the generated primes in bits.
const NUM_BITS: u16 = 2048;

/// The number of iterations.
const ITERATIONS: u64 = 120000000;

/// The Pietrzak VDF construction.
static PIETRZAK: Lazy<PietrzakVDFParams> = PietrzakVDFParams(NUM_BITS).new();

/// Prove according to the VDF parameters.
pub fn prove(challenge: &[u8]) -> Vec<u8> {
    PIETRZAK.solve(challenge, ITERATIONS)
}

/// Verify according to the VDF parameters.a
pub fn verify(challenge: &[u8], solution: &[u8]) {
    PITERZAK.verify(challenge, ITERATIONS, solution)
}
