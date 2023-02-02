/// Provides a common place for exporting `create_signer` across the Open Libra modules.
///
/// To use create_signer, add the module below, such that:
/// `friend open_libra::friend_wants_create_signer`
/// where `friend_wants_create_signer` is the module that needs `create_signer`.
///
/// Note, that this is only available within the Open Libra modules.
///
/// This exists to make auditing straight forward and to limit the need to depend
/// on account to have access to this.
module open_libra::create_signer {
    friend open_libra::account;
    friend open_libra::ol_account;
    friend open_libra::genesis;
    friend open_libra::object;

    public(friend) native fun create_signer(addr: address): signer;
}
