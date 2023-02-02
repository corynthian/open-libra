module std::vdf {
    /// Verifies a VDF proof.
    native public fun verify(
	challenge: &vector<u8>,
	solution: &vector<u8>,
	difficulty: u64,
	security: u64,
    ): bool;

    /// This is used for the 0th proof in a delay tower to ensure the tower belongs to a specific
    /// authentication key and address.
    native public fun address_from_challenge(challenge: &vector<u8>): (address, vector<u8>);
}
