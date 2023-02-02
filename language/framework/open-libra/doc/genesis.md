
<a name="0x1_genesis"></a>

# Module `0x1::genesis`



-  [Struct `AccountMap`](#0x1_genesis_AccountMap)
-  [Struct `ExistingAccountMap`](#0x1_genesis_ExistingAccountMap)
-  [Struct `ValidatorConfiguration`](#0x1_genesis_ValidatorConfiguration)
-  [Struct `ValidatorConfigurationWithCommission`](#0x1_genesis_ValidatorConfigurationWithCommission)
-  [Constants](#@Constants_0)
-  [Function `initialize`](#0x1_genesis_initialize)
-  [Function `initialize_ol_coin`](#0x1_genesis_initialize_ol_coin)
-  [Function `initialize_core_resources_and_ol_coin`](#0x1_genesis_initialize_core_resources_and_ol_coin)
-  [Function `create_accounts`](#0x1_genesis_create_accounts)
-  [Function `create_account`](#0x1_genesis_create_account)
-  [Function `create_initialize_validators_with_commission`](#0x1_genesis_create_initialize_validators_with_commission)
-  [Function `create_initialize_validators`](#0x1_genesis_create_initialize_validators)
-  [Function `create_initialize_validator`](#0x1_genesis_create_initialize_validator)
-  [Function `initialize_validator`](#0x1_genesis_initialize_validator)
-  [Function `set_genesis_end`](#0x1_genesis_set_genesis_end)
-  [Function `initialize_for_verification`](#0x1_genesis_initialize_for_verification)


<pre><code><b>use</b> <a href="account.md#0x1_account">0x1::account</a>;
<b>use</b> <a href="aggregator_factory.md#0x1_aggregator_factory">0x1::aggregator_factory</a>;
<b>use</b> <a href="block.md#0x1_block">0x1::block</a>;
<b>use</b> <a href="chain_id.md#0x1_chain_id">0x1::chain_id</a>;
<b>use</b> <a href="chain_status.md#0x1_chain_status">0x1::chain_status</a>;
<b>use</b> <a href="coin.md#0x1_coin">0x1::coin</a>;
<b>use</b> <a href="consensus_config.md#0x1_consensus_config">0x1::consensus_config</a>;
<b>use</b> <a href="create_signer.md#0x1_create_signer">0x1::create_signer</a>;
<b>use</b> <a href="../../std/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="../../std/doc/features.md#0x1_features">0x1::features</a>;
<b>use</b> <a href="gas_schedule.md#0x1_gas_schedule">0x1::gas_schedule</a>;
<b>use</b> <a href="ol_coin.md#0x1_ol_coin">0x1::ol_coin</a>;
<b>use</b> <a href="reconfiguration.md#0x1_reconfiguration">0x1::reconfiguration</a>;
<b>use</b> <a href="state_storage.md#0x1_state_storage">0x1::state_storage</a>;
<b>use</b> <a href="storage_gas.md#0x1_storage_gas">0x1::storage_gas</a>;
<b>use</b> <a href="timestamp.md#0x1_timestamp">0x1::timestamp</a>;
<b>use</b> <a href="transaction_fee.md#0x1_transaction_fee">0x1::transaction_fee</a>;
<b>use</b> <a href="transaction_validation.md#0x1_transaction_validation">0x1::transaction_validation</a>;
<b>use</b> <a href="validator.md#0x1_validator">0x1::validator</a>;
<b>use</b> <a href="../../std/doc/vector.md#0x1_vector">0x1::vector</a>;
<b>use</b> <a href="version.md#0x1_version">0x1::version</a>;
</code></pre>



<a name="0x1_genesis_AccountMap"></a>

## Struct `AccountMap`



<pre><code><b>struct</b> <a href="genesis.md#0x1_genesis_AccountMap">AccountMap</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>account_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>balance: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_genesis_ExistingAccountMap"></a>

## Struct `ExistingAccountMap`

Map containing accounts which existed pre-genesis.


<pre><code><b>struct</b> <a href="genesis.md#0x1_genesis_ExistingAccountMap">ExistingAccountMap</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>accounts: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>allocations: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u64&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_genesis_ValidatorConfiguration"></a>

## Struct `ValidatorConfiguration`



<pre><code><b>struct</b> <a href="genesis.md#0x1_genesis_ValidatorConfiguration">ValidatorConfiguration</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>owner_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>operator_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>voter_address: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>initial_allocation: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>consensus_pubkey: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>proof_of_possession: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>network_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>full_node_network_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_genesis_ValidatorConfigurationWithCommission"></a>

## Struct `ValidatorConfigurationWithCommission`



<pre><code><b>struct</b> <a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>validator_config: <a href="genesis.md#0x1_genesis_ValidatorConfiguration">genesis::ValidatorConfiguration</a></code>
</dt>
<dd>

</dd>
<dt>
<code>commission_percentage: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>join_during_genesis: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x1_genesis_EACCOUNT_DOES_NOT_EXIST"></a>



<pre><code><b>const</b> <a href="genesis.md#0x1_genesis_EACCOUNT_DOES_NOT_EXIST">EACCOUNT_DOES_NOT_EXIST</a>: u64 = 2;
</code></pre>



<a name="0x1_genesis_EDUPLICATE_ACCOUNT"></a>



<pre><code><b>const</b> <a href="genesis.md#0x1_genesis_EDUPLICATE_ACCOUNT">EDUPLICATE_ACCOUNT</a>: u64 = 1;
</code></pre>



<a name="0x1_genesis_initialize"></a>

## Function `initialize`

Genesis step 1: Initialize ol framework account and core modules on chain.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize">initialize</a>(<a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8, initial_version: u64, <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, epoch_interval_microsecs: u64, _vdf_difficulty: u64, _vdf_threshold: u64, _recurring_lockup_duration_secs: u64, _allow_validator_set_change: bool, _rewards_rate: u64, _rewards_rate_denominator: u64, _voting_power_increase_limit: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize">initialize</a>(
    <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
    initial_version: u64,
    <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    epoch_interval_microsecs: u64,
	_vdf_difficulty: u64,
	_vdf_threshold: u64,
    _recurring_lockup_duration_secs: u64,
    _allow_validator_set_change: bool,
    _rewards_rate: u64,
    _rewards_rate_denominator: u64,
    _voting_power_increase_limit: u64,
) {
    // Initialize the open libra <a href="account.md#0x1_account">account</a>. This is the <a href="account.md#0x1_account">account</a> <b>where</b> system resources and modules
	// will be deployed <b>to</b>. This will be entirely managed by on-chain governance and no entities have the key or privileges
    // <b>to</b> <b>use</b> this <a href="account.md#0x1_account">account</a>.
    <b>let</b> (open_libra, _ol_signer_cap) = <a href="account.md#0x1_account_create_framework_reserved_account">account::create_framework_reserved_account</a>(@open_libra);
    // Initialize <a href="account.md#0x1_account">account</a> configs on ol framework <a href="account.md#0x1_account">account</a>.
    <a href="account.md#0x1_account_initialize">account::initialize</a>(&open_libra);

    <a href="transaction_validation.md#0x1_transaction_validation_initialize">transaction_validation::initialize</a>(
        &open_libra,
        b"script_prologue",
        b"module_prologue",
        b"multi_agent_script_prologue",
        b"epilogue",
    );

    // Give the decentralized on-chain governance control over the core framework <a href="account.md#0x1_account">account</a>.
    // governance::store_signer_cap(&open_libra, @open_libra, open_libra_signer_cap);

    // Give governance control over the reserved addresses.
    // <b>let</b> reserved_addresses = <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;[@0x2, @0x3, @0x4, @0x5, @0x6, @0x7, @0x8, @0x9, @0xa];
    // <b>while</b> (!<a href="../../std/doc/vector.md#0x1_vector_is_empty">vector::is_empty</a>(&reserved_addresses)) {
    //     <b>let</b> <b>address</b> = <a href="../../std/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>&lt;<b>address</b>&gt;(&<b>mut</b> reserved_addresses);
    //     <b>let</b> (open_libra, reserved_signer_cap) = account::create_reserved_account(<b>address</b>);
    //     governance::store_signer_cap(&open_libra, <b>address</b>, reserved_signer_cap);
    // };

    <a href="consensus_config.md#0x1_consensus_config_initialize">consensus_config::initialize</a>(&open_libra, <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>);
    <a href="version.md#0x1_version_initialize">version::initialize</a>(&open_libra, initial_version);

    <a href="validator.md#0x1_validator_initialize">validator::initialize</a>(&open_libra);

	// 0L-TODO
    // tower_config::initialize(
    //     &open_libra,
    //     vdf_difficulty,
    //     vdf_threshold,
    //     recurring_lockup_duration_secs,
    //     allow_validator_set_change,
    //     rewards_rate,
    //     rewards_rate_denominator,
    //     voting_power_increase_limit,
    // );

    <a href="storage_gas.md#0x1_storage_gas_initialize">storage_gas::initialize</a>(&open_libra);
    <a href="gas_schedule.md#0x1_gas_schedule_initialize">gas_schedule::initialize</a>(&open_libra, <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>);

    // Ensure we can create aggregators for supply, but not enable it for common <b>use</b> just yet.
    <a href="aggregator_factory.md#0x1_aggregator_factory_initialize_aggregator_factory">aggregator_factory::initialize_aggregator_factory</a>(&open_libra);
    <a href="coin.md#0x1_coin_initialize_supply_config">coin::initialize_supply_config</a>(&open_libra);

    <a href="chain_id.md#0x1_chain_id_initialize">chain_id::initialize</a>(&open_libra, <a href="chain_id.md#0x1_chain_id">chain_id</a>);
    <a href="reconfiguration.md#0x1_reconfiguration_initialize">reconfiguration::initialize</a>(&open_libra);
    <a href="block.md#0x1_block_initialize">block::initialize</a>(&open_libra, epoch_interval_microsecs);
    <a href="state_storage.md#0x1_state_storage_initialize">state_storage::initialize</a>(&open_libra);
    <a href="timestamp.md#0x1_timestamp_set_time_has_started">timestamp::set_time_has_started</a>(&open_libra);
}
</code></pre>



</details>

<a name="0x1_genesis_initialize_ol_coin"></a>

## Function `initialize_ol_coin`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_ol_coin">initialize_ol_coin</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_ol_coin">initialize_ol_coin</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>) {
    <b>let</b> (burn_cap, mint_cap) = <a href="ol_coin.md#0x1_ol_coin_initialize">ol_coin::initialize</a>(open_libra);
    // Give the `<a href="validator.md#0x1_validator">validator</a>` <b>module</b> MintCapability&lt;OLCoin&gt; so it can mint rewards.
    <a href="validator.md#0x1_validator_store_ol_coin_mint_cap">validator::store_ol_coin_mint_cap</a>(open_libra, mint_cap);
    // Give <a href="transaction_fee.md#0x1_transaction_fee">transaction_fee</a> <b>module</b> BurnCapability&lt;OLCoin&gt; so it can burn gas.
    <a href="transaction_fee.md#0x1_transaction_fee_store_ol_coin_burn_cap">transaction_fee::store_ol_coin_burn_cap</a>(open_libra, burn_cap);
}
</code></pre>



</details>

<a name="0x1_genesis_initialize_core_resources_and_ol_coin"></a>

## Function `initialize_core_resources_and_ol_coin`

Only called for testnets and e2e tests.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_core_resources_and_ol_coin">initialize_core_resources_and_ol_coin</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, core_resources_auth_key: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_core_resources_and_ol_coin">initialize_core_resources_and_ol_coin</a>(
    open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>,
    core_resources_auth_key: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) {
    <b>let</b> (burn_cap, mint_cap) = <a href="ol_coin.md#0x1_ol_coin_initialize">ol_coin::initialize</a>(open_libra);
    // Give `<a href="validator.md#0x1_validator">validator</a>` <b>module</b> MintCapability&lt;OLCoin&gt; so it can mint rewards.
    <a href="validator.md#0x1_validator_store_ol_coin_mint_cap">validator::store_ol_coin_mint_cap</a>(open_libra, mint_cap);
    // Give <a href="transaction_fee.md#0x1_transaction_fee">transaction_fee</a> <b>module</b> BurnCapability&lt;OLCoin&gt; so it can burn gas.
    <a href="transaction_fee.md#0x1_transaction_fee_store_ol_coin_burn_cap">transaction_fee::store_ol_coin_burn_cap</a>(open_libra, burn_cap);

    <b>let</b> core_resources = <a href="account.md#0x1_account_create_account">account::create_account</a>(@core_resources);
    <a href="account.md#0x1_account_rotate_authentication_key_internal">account::rotate_authentication_key_internal</a>(&core_resources, core_resources_auth_key);
    <a href="ol_coin.md#0x1_ol_coin_configure_accounts_for_test">ol_coin::configure_accounts_for_test</a>(open_libra, &core_resources, mint_cap);
}
</code></pre>



</details>

<a name="0x1_genesis_create_accounts"></a>

## Function `create_accounts`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_accounts">create_accounts</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, accounts: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_AccountMap">genesis::AccountMap</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_accounts">create_accounts</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, accounts: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_AccountMap">AccountMap</a>&gt;) {
    <b>let</b> i = 0;
    <b>let</b> num_accounts = <a href="../../std/doc/vector.md#0x1_vector_length">vector::length</a>(&accounts);
    <b>let</b> unique_accounts = <a href="../../std/doc/vector.md#0x1_vector_empty">vector::empty</a>();

    <b>while</b> (i &lt; num_accounts) {
        <b>let</b> account_map = <a href="../../std/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&accounts, i);
        <b>assert</b>!(
            !<a href="../../std/doc/vector.md#0x1_vector_contains">vector::contains</a>(&unique_accounts, &account_map.account_address),
            <a href="../../std/doc/error.md#0x1_error_already_exists">error::already_exists</a>(<a href="genesis.md#0x1_genesis_EDUPLICATE_ACCOUNT">EDUPLICATE_ACCOUNT</a>),
        );
        <a href="../../std/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> unique_accounts, account_map.account_address);

        <a href="genesis.md#0x1_genesis_create_account">create_account</a>(
            open_libra,
            account_map.account_address,
            account_map.balance,
        );

        i = i + 1;
    };
}
</code></pre>



</details>

<a name="0x1_genesis_create_account"></a>

## Function `create_account`

This creates an funds an account if it doesn't exist.
If it exists, it just returns the signer.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_account">create_account</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, account_address: <b>address</b>, balance: u64): <a href="../../std/doc/signer.md#0x1_signer">signer</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_account">create_account</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, account_address: <b>address</b>, balance: u64): <a href="../../std/doc/signer.md#0x1_signer">signer</a> {
    <b>if</b> (<a href="account.md#0x1_account_exists_at">account::exists_at</a>(account_address)) {
        <a href="create_signer.md#0x1_create_signer">create_signer</a>(account_address)
    } <b>else</b> {
        <b>let</b> <a href="account.md#0x1_account">account</a> = <a href="account.md#0x1_account_create_account">account::create_account</a>(account_address);
        <a href="coin.md#0x1_coin_register">coin::register</a>&lt;OLCoin&gt;(&<a href="account.md#0x1_account">account</a>);
        <a href="ol_coin.md#0x1_ol_coin_mint">ol_coin::mint</a>(open_libra, account_address, balance);
        <a href="account.md#0x1_account">account</a>
    }
}
</code></pre>



</details>

<a name="0x1_genesis_create_initialize_validators_with_commission"></a>

## Function `create_initialize_validators_with_commission`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validators_with_commission">create_initialize_validators_with_commission</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, validators: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">genesis::ValidatorConfigurationWithCommission</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validators_with_commission">create_initialize_validators_with_commission</a>(
    open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>,
    validators: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a>&gt;,
) {
    <b>let</b> i = 0;
    <b>let</b> num_validators = <a href="../../std/doc/vector.md#0x1_vector_length">vector::length</a>(&validators);
    <b>while</b> (i &lt; num_validators) {
        <b>let</b> <a href="validator.md#0x1_validator">validator</a> = <a href="../../std/doc/vector.md#0x1_vector_borrow">vector::borrow</a>(&validators, i);
        <a href="genesis.md#0x1_genesis_create_initialize_validator">create_initialize_validator</a>(open_libra, <a href="validator.md#0x1_validator">validator</a>);
        i = i + 1;
    };

    // Destroy open libras ability <b>to</b> mint coins now that we're done <b>with</b> setting up the initial
    // validators.
    <a href="ol_coin.md#0x1_ol_coin_destroy_mint_cap">ol_coin::destroy_mint_cap</a>(open_libra);

	// 0L-TODO: Transition <b>to</b> the next epoch
    // validator::on_new_epoch();
}
</code></pre>



</details>

<a name="0x1_genesis_create_initialize_validators"></a>

## Function `create_initialize_validators`

Sets up the initial validator set for the network.
The validator "owner" accounts, and their authentication
Addresses (and keys) are encoded in the <code>owners</code>
Each validator signs consensus messages with the private key corresponding to the Ed25519
public key in <code>consensus_pubkeys</code>.
Finally, each validator must specify the network address
(see types/src/network_address/mod.rs) for itself and its full nodes.

Network address fields are a vector per account, where each entry is a vector of addresses
encoded in a single BCS byte array.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validators">create_initialize_validators</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, validators: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfiguration">genesis::ValidatorConfiguration</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validators">create_initialize_validators</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, validators: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfiguration">ValidatorConfiguration</a>&gt;) {
    <b>let</b> i = 0;
    <b>let</b> num_validators = <a href="../../std/doc/vector.md#0x1_vector_length">vector::length</a>(&validators);

    <b>let</b> validators_with_commission = <a href="../../std/doc/vector.md#0x1_vector_empty">vector::empty</a>();

    <b>while</b> (i &lt; num_validators) {
        <b>let</b> validator_with_commission = <a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a> {
            validator_config: <a href="../../std/doc/vector.md#0x1_vector_pop_back">vector::pop_back</a>(&<b>mut</b> validators),
            commission_percentage: 0,
            join_during_genesis: <b>true</b>,
        };
        <a href="../../std/doc/vector.md#0x1_vector_push_back">vector::push_back</a>(&<b>mut</b> validators_with_commission, validator_with_commission);

        i = i + 1;
    };

    <a href="genesis.md#0x1_genesis_create_initialize_validators_with_commission">create_initialize_validators_with_commission</a>(open_libra, validators_with_commission);
}
</code></pre>



</details>

<a name="0x1_genesis_create_initialize_validator"></a>

## Function `create_initialize_validator`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validator">create_initialize_validator</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, commission_config: &<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">genesis::ValidatorConfigurationWithCommission</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_create_initialize_validator">create_initialize_validator</a>(
    open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>,
    commission_config: &<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a>,
) {
    <b>let</b> <a href="validator.md#0x1_validator">validator</a> = &commission_config.validator_config;

    <b>let</b> _owner = &<a href="genesis.md#0x1_genesis_create_account">create_account</a>(open_libra, <a href="validator.md#0x1_validator">validator</a>.owner_address, <a href="validator.md#0x1_validator">validator</a>.initial_allocation);
    <a href="genesis.md#0x1_genesis_create_account">create_account</a>(open_libra, <a href="validator.md#0x1_validator">validator</a>.operator_address, 0);
    <a href="genesis.md#0x1_genesis_create_account">create_account</a>(open_libra, <a href="validator.md#0x1_validator">validator</a>.voter_address, 0);

	// 0L-TODO
    // Initialize the stake pool and join the <a href="validator.md#0x1_validator">validator</a> set.
    // <b>let</b> pool_address = <b>if</b> (use_staking_contract) {
    //     staking_contract::create_staking_contract(
    //         owner,
    //         <a href="validator.md#0x1_validator">validator</a>.operator_address,
    //         <a href="validator.md#0x1_validator">validator</a>.voter_address,
    //         <a href="validator.md#0x1_validator">validator</a>.stake_amount,
    //         commission_config.commission_percentage,
    //         x"",
    //     );
    //     staking_contract::stake_pool_address(<a href="validator.md#0x1_validator">validator</a>.owner_address, <a href="validator.md#0x1_validator">validator</a>.operator_address)
    // } <b>else</b> {
    //     stake::initialize_stake_owner(
    //         owner,
    //         <a href="validator.md#0x1_validator">validator</a>.stake_amount,
    //         <a href="validator.md#0x1_validator">validator</a>.operator_address,
    //         <a href="validator.md#0x1_validator">validator</a>.voter_address,
    //     );
    //     <a href="validator.md#0x1_validator">validator</a>.owner_address
    // };

    // <b>if</b> (commission_config.join_during_genesis) {
    //     <a href="genesis.md#0x1_genesis_initialize_validator">initialize_validator</a>(pool_address, <a href="validator.md#0x1_validator">validator</a>);
    // };
}
</code></pre>



</details>

<a name="0x1_genesis_initialize_validator"></a>

## Function `initialize_validator`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_validator">initialize_validator</a>(_pool_address: <b>address</b>, <a href="validator.md#0x1_validator">validator</a>: &<a href="genesis.md#0x1_genesis_ValidatorConfiguration">genesis::ValidatorConfiguration</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_validator">initialize_validator</a>(_pool_address: <b>address</b>, <a href="validator.md#0x1_validator">validator</a>: &<a href="genesis.md#0x1_genesis_ValidatorConfiguration">ValidatorConfiguration</a>) {
    <b>let</b> _operator = &<a href="create_signer.md#0x1_create_signer">create_signer</a>(<a href="validator.md#0x1_validator">validator</a>.operator_address);

	// 0L-TODO
    // stake::rotate_consensus_key(
    //     operator,
    //     pool_address,
    //     <a href="validator.md#0x1_validator">validator</a>.consensus_pubkey,
    //     <a href="validator.md#0x1_validator">validator</a>.proof_of_possession,
    // );
    // stake::update_network_and_fullnode_addresses(
    //     operator,
    //     pool_address,
    //     <a href="validator.md#0x1_validator">validator</a>.network_addresses,
    //     <a href="validator.md#0x1_validator">validator</a>.full_node_network_addresses,
    // );
    // stake::join_validator_set_internal(operator, pool_address);
}
</code></pre>



</details>

<a name="0x1_genesis_set_genesis_end"></a>

## Function `set_genesis_end`

The last step of genesis.


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_set_genesis_end">set_genesis_end</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_set_genesis_end">set_genesis_end</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>) {
    <a href="chain_status.md#0x1_chain_status_set_genesis_end">chain_status::set_genesis_end</a>(open_libra);
}
</code></pre>



</details>

<a name="0x1_genesis_initialize_for_verification"></a>

## Function `initialize_for_verification`



<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_for_verification">initialize_for_verification</a>(<a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8, initial_version: u64, <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, epoch_interval_microsecs: u64, minimum_stake: u64, maximum_stake: u64, recurring_lockup_duration_secs: u64, allow_validator_set_change: bool, rewards_rate: u64, rewards_rate_denominator: u64, voting_power_increase_limit: u64, open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, _min_voting_threshold: u128, _required_proposer_stake: u64, _voting_duration_secs: u64, accounts: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_AccountMap">genesis::AccountMap</a>&gt;, validators: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">genesis::ValidatorConfigurationWithCommission</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="genesis.md#0x1_genesis_initialize_for_verification">initialize_for_verification</a>(
    <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    <a href="chain_id.md#0x1_chain_id">chain_id</a>: u8,
    initial_version: u64,
    <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    epoch_interval_microsecs: u64,
    minimum_stake: u64,
    maximum_stake: u64,
    recurring_lockup_duration_secs: u64,
    allow_validator_set_change: bool,
    rewards_rate: u64,
    rewards_rate_denominator: u64,
    voting_power_increase_limit: u64,
    open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>,
    _min_voting_threshold: u128,
    _required_proposer_stake: u64,
    _voting_duration_secs: u64,
    accounts: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_AccountMap">AccountMap</a>&gt;,
    // _employee_vesting_start: u64,
    // _employee_vesting_period_duration: u64,
    // _employees: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;EmployeeAccountMap&gt;,
    validators: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="genesis.md#0x1_genesis_ValidatorConfigurationWithCommission">ValidatorConfigurationWithCommission</a>&gt;
) {
    <a href="genesis.md#0x1_genesis_initialize">initialize</a>(
        <a href="gas_schedule.md#0x1_gas_schedule">gas_schedule</a>,
        <a href="chain_id.md#0x1_chain_id">chain_id</a>,
        initial_version,
        <a href="consensus_config.md#0x1_consensus_config">consensus_config</a>,
        epoch_interval_microsecs,
        minimum_stake,
        maximum_stake,
        recurring_lockup_duration_secs,
        allow_validator_set_change,
        rewards_rate,
        rewards_rate_denominator,
        voting_power_increase_limit
    );
    <a href="../../std/doc/features.md#0x1_features_change_feature_flags">features::change_feature_flags</a>(open_libra, <a href="../../std/doc/vector.md#0x1_vector">vector</a>[1, 2], <a href="../../std/doc/vector.md#0x1_vector">vector</a>[]);
    <a href="genesis.md#0x1_genesis_initialize_ol_coin">initialize_ol_coin</a>(open_libra);
    // governance::initialize_for_verification(
    //     open_libra,
    //     min_voting_threshold,
    //     required_proposer_stake,
    //     voting_duration_secs
    // );
    <a href="genesis.md#0x1_genesis_create_accounts">create_accounts</a>(open_libra, accounts);
    // create_employee_validators(employee_vesting_start, employee_vesting_period_duration, employees);
    <a href="genesis.md#0x1_genesis_create_initialize_validators_with_commission">create_initialize_validators_with_commission</a>(open_libra, validators);
    <a href="genesis.md#0x1_genesis_set_genesis_end">set_genesis_end</a>(open_libra);
}
</code></pre>



</details>


[move-book]: https://move-language.github.io/move/introduction.html
