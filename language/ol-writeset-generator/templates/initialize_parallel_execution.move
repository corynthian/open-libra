script {
    use open_libra::parallel_execution_config;
    fun main(ol_root: signer, _execute_as: signer) {
        parallel_execution_config::initialize_parallel_execution(&ol_root);
    }
}
