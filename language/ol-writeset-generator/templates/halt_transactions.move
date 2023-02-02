script {
    use open_libra::transaction_publishing_option;
    fun main(ol_root: signer) {
        transaction_publishing_option::halt_all_transactions(&ol_root);
    }
}
