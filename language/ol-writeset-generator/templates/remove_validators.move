script {
    use open_libra::validator_set;
    fun main(ol_root: signer) {
        {{#each addresses}}
        validator_set::remove_validator(&ol_root, @0x{{this}});
        {{/each}}
    }
}
