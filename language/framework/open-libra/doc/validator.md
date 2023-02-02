
<a name="0x1_validator"></a>

# Module `0x1::validator`


* Validator life-cycle:
* 1. Prepares node setup procedure by calling <code><a href="validator.md#0x1_validator_initialize_validator">validator::initialize_validator</a></code>.



-  [Resource `OwnerCapability`](#0x1_validator_OwnerCapability)
-  [Resource `ValidatorConfig`](#0x1_validator_ValidatorConfig)
-  [Struct `ValidatorInfo`](#0x1_validator_ValidatorInfo)
-  [Resource `ValidatorSet`](#0x1_validator_ValidatorSet)
-  [Resource `OLCoinCapabilities`](#0x1_validator_OLCoinCapabilities)
-  [Struct `IndividualValidatorPerformance`](#0x1_validator_IndividualValidatorPerformance)
-  [Resource `ValidatorPerformance`](#0x1_validator_ValidatorPerformance)
-  [Struct `SetOperatorEvent`](#0x1_validator_SetOperatorEvent)
-  [Struct `AddTowerEvent`](#0x1_validator_AddTowerEvent)
-  [Struct `ReactivateTowerEvent`](#0x1_validator_ReactivateTowerEvent)
-  [Struct `RotateConsensusKeyEvent`](#0x1_validator_RotateConsensusKeyEvent)
-  [Struct `UpdateNetworkAndFullnodeAddressesEvent`](#0x1_validator_UpdateNetworkAndFullnodeAddressesEvent)
-  [Struct `DistributeRewardsEvent`](#0x1_validator_DistributeRewardsEvent)
-  [Resource `ValidatorFees`](#0x1_validator_ValidatorFees)
-  [Constants](#@Constants_0)
-  [Function `initialize_validator_fees`](#0x1_validator_initialize_validator_fees)
-  [Function `add_transaction_fee`](#0x1_validator_add_transaction_fee)
-  [Function `initialize`](#0x1_validator_initialize)
-  [Function `store_ol_coin_mint_cap`](#0x1_validator_store_ol_coin_mint_cap)
-  [Function `initialize_validator`](#0x1_validator_initialize_validator)


<pre><code><b>use</b> <a href="../../std/doc/bls12381.md#0x1_bls12381">0x1::bls12381</a>;
<b>use</b> <a href="coin.md#0x1_coin">0x1::coin</a>;
<b>use</b> <a href="../../std/doc/error.md#0x1_error">0x1::error</a>;
<b>use</b> <a href="ol_coin.md#0x1_ol_coin">0x1::ol_coin</a>;
<b>use</b> <a href="../../std/doc/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="system_addresses.md#0x1_system_addresses">0x1::system_addresses</a>;
<b>use</b> <a href="../../std/doc/table.md#0x1_table">0x1::table</a>;
</code></pre>



<a name="0x1_validator_OwnerCapability"></a>

## Resource `OwnerCapability`

Capability that represents ownership and can be used to control the validator and the associated
stake pool. Having this be separate from the signer for the account that the validator resources
are hosted at allows modules to have control over a validator.


<pre><code><b>struct</b> <a href="validator.md#0x1_validator_OwnerCapability">OwnerCapability</a> <b>has</b> store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>pool_address: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_ValidatorConfig"></a>

## Resource `ValidatorConfig`

Validator info stored in validator address.


<pre><code><b>struct</b> <a href="validator.md#0x1_validator_ValidatorConfig">ValidatorConfig</a> <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>consensus_pubkey: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>network_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>fullnode_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>validator_index: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_ValidatorInfo"></a>

## Struct `ValidatorInfo`

Consensus information per validator, stored in ValidatorSet.


<pre><code><b>struct</b> <a href="validator.md#0x1_validator_ValidatorInfo">ValidatorInfo</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>addr: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>voting_power: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>config: <a href="validator.md#0x1_validator_ValidatorConfig">validator::ValidatorConfig</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_ValidatorSet"></a>

## Resource `ValidatorSet`

Full ValidatorSet, stored at @open_libra.
1. <code>join_validator_set</code> adds to <code>pending_active</code> queue.
2. <code>leave_validator_set</code> moves from active to <code>pending_inactive</code> queue.
3. <code>on_new_epoch</code> processes two pending queues and refresh ValidatorInfo from the owners
address.


<pre><code><b>struct</b> <a href="validator.md#0x1_validator_ValidatorSet">ValidatorSet</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>consensus_scheme: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>active_validators: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="validator.md#0x1_validator_ValidatorInfo">validator::ValidatorInfo</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>pending_inactive: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="validator.md#0x1_validator_ValidatorInfo">validator::ValidatorInfo</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>pending_active: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="validator.md#0x1_validator_ValidatorInfo">validator::ValidatorInfo</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>total_voting_power: u128</code>
</dt>
<dd>

</dd>
<dt>
<code>total_joining_power: u128</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_OLCoinCapabilities"></a>

## Resource `OLCoinCapabilities`

OLCoin capabilities, set during genesis and stored in @CoreResource account.
This allows the <code><a href="validator.md#0x1_validator">validator</a></code> module to mint rewards to stakers.


<pre><code><b>struct</b> <a href="validator.md#0x1_validator_OLCoinCapabilities">OLCoinCapabilities</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>mint_cap: <a href="coin.md#0x1_coin_MintCapability">coin::MintCapability</a>&lt;<a href="ol_coin.md#0x1_ol_coin_OLCoin">ol_coin::OLCoin</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_IndividualValidatorPerformance"></a>

## Struct `IndividualValidatorPerformance`



<pre><code><b>struct</b> <a href="validator.md#0x1_validator_IndividualValidatorPerformance">IndividualValidatorPerformance</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>successful_proposals: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>failed_proposals: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_ValidatorPerformance"></a>

## Resource `ValidatorPerformance`



<pre><code><b>struct</b> <a href="validator.md#0x1_validator_ValidatorPerformance">ValidatorPerformance</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>validators: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;<a href="validator.md#0x1_validator_IndividualValidatorPerformance">validator::IndividualValidatorPerformance</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_SetOperatorEvent"></a>

## Struct `SetOperatorEvent`



<pre><code><b>struct</b> <a href="validator.md#0x1_validator_SetOperatorEvent">SetOperatorEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>old_operator: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>new_operator: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_AddTowerEvent"></a>

## Struct `AddTowerEvent`



<pre><code><b>struct</b> <a href="validator.md#0x1_validator_AddTowerEvent">AddTowerEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>tower_height_added: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_ReactivateTowerEvent"></a>

## Struct `ReactivateTowerEvent`



<pre><code><b>struct</b> <a href="validator.md#0x1_validator_ReactivateTowerEvent">ReactivateTowerEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>tower_height: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_RotateConsensusKeyEvent"></a>

## Struct `RotateConsensusKeyEvent`



<pre><code><b>struct</b> <a href="validator.md#0x1_validator_RotateConsensusKeyEvent">RotateConsensusKeyEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>old_consensus_pubkey: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>new_consensus_pubkey: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_UpdateNetworkAndFullnodeAddressesEvent"></a>

## Struct `UpdateNetworkAndFullnodeAddressesEvent`



<pre><code><b>struct</b> <a href="validator.md#0x1_validator_UpdateNetworkAndFullnodeAddressesEvent">UpdateNetworkAndFullnodeAddressesEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>old_network_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>new_network_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>old_fullnode_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>new_fullnode_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_DistributeRewardsEvent"></a>

## Struct `DistributeRewardsEvent`



<pre><code><b>struct</b> <a href="validator.md#0x1_validator_DistributeRewardsEvent">DistributeRewardsEvent</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>rewards_amount: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x1_validator_ValidatorFees"></a>

## Resource `ValidatorFees`

Stores transaction fees assigned to validators. All fees are distributed to validators
at the end of the epoch.


<pre><code><b>struct</b> <a href="validator.md#0x1_validator_ValidatorFees">ValidatorFees</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>fees_table: <a href="../../std/doc/table.md#0x1_table_Table">table::Table</a>&lt;<b>address</b>, <a href="coin.md#0x1_coin_Coin">coin::Coin</a>&lt;<a href="ol_coin.md#0x1_ol_coin_OLCoin">ol_coin::OLCoin</a>&gt;&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x1_validator_EALREADY_ACTIVE_VALIDATOR"></a>

Account is already a validator or pending validator.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EALREADY_ACTIVE_VALIDATOR">EALREADY_ACTIVE_VALIDATOR</a>: u64 = 3;
</code></pre>



<a name="0x1_validator_EALREADY_REGISTERED"></a>

Account is already registered as a validator candidate.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EALREADY_REGISTERED">EALREADY_REGISTERED</a>: u64 = 6;
</code></pre>



<a name="0x1_validator_EFEES_TABLE_ALREADY_EXISTS"></a>

Table to store collected transaction fees for each validator already exists.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EFEES_TABLE_ALREADY_EXISTS">EFEES_TABLE_ALREADY_EXISTS</a>: u64 = 15;
</code></pre>



<a name="0x1_validator_EINELIGIBLE_VALIDATOR"></a>

Validator is not defined in the ACL of entities allowed to be validators.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EINELIGIBLE_VALIDATOR">EINELIGIBLE_VALIDATOR</a>: u64 = 14;
</code></pre>



<a name="0x1_validator_EINVALID_PROOF"></a>

The verifiable delay proof is invalid.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EINVALID_PROOF">EINVALID_PROOF</a>: u64 = 2;
</code></pre>



<a name="0x1_validator_EINVALID_PUBLIC_KEY"></a>

Invalid consensus public key


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EINVALID_PUBLIC_KEY">EINVALID_PUBLIC_KEY</a>: u64 = 9;
</code></pre>



<a name="0x1_validator_ELAST_VALIDATOR"></a>

Can't remove last validator.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_ELAST_VALIDATOR">ELAST_VALIDATOR</a>: u64 = 5;
</code></pre>



<a name="0x1_validator_ENOT_OPERATOR"></a>

Account does not have the right operator capability.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_ENOT_OPERATOR">ENOT_OPERATOR</a>: u64 = 7;
</code></pre>



<a name="0x1_validator_ENOT_VALIDATOR"></a>

Account is not a validator.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_ENOT_VALIDATOR">ENOT_VALIDATOR</a>: u64 = 4;
</code></pre>



<a name="0x1_validator_ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED"></a>

Validators cannot join or leave post genesis on this test network.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED">ENO_POST_GENESIS_VALIDATOR_SET_CHANGE_ALLOWED</a>: u64 = 8;
</code></pre>



<a name="0x1_validator_EOWNER_CAP_ALREADY_EXISTS"></a>

An account cannot own more than one owner capability.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EOWNER_CAP_ALREADY_EXISTS">EOWNER_CAP_ALREADY_EXISTS</a>: u64 = 13;
</code></pre>



<a name="0x1_validator_EOWNER_CAP_NOT_FOUND"></a>

Owner capability does not exist at the provided account.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EOWNER_CAP_NOT_FOUND">EOWNER_CAP_NOT_FOUND</a>: u64 = 12;
</code></pre>



<a name="0x1_validator_EVALIDATOR_CONFIG"></a>

Validator Config not published.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EVALIDATOR_CONFIG">EVALIDATOR_CONFIG</a>: u64 = 1;
</code></pre>



<a name="0x1_validator_EVALIDATOR_SET_TOO_LARGE"></a>

Validator set exceeds the limit


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EVALIDATOR_SET_TOO_LARGE">EVALIDATOR_SET_TOO_LARGE</a>: u64 = 10;
</code></pre>



<a name="0x1_validator_EVOTING_POWER_INCREASE_EXCEEDS_LIMIT"></a>

Voting power increase has exceeded the limit for this current epoch.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_EVOTING_POWER_INCREASE_EXCEEDS_LIMIT">EVOTING_POWER_INCREASE_EXCEEDS_LIMIT</a>: u64 = 11;
</code></pre>



<a name="0x1_validator_MAX_REWARDS_RATE"></a>

Limit the maximum value of <code>rewards_rate</code> in order to avoid any arithmetic overflow.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_MAX_REWARDS_RATE">MAX_REWARDS_RATE</a>: u64 = 1000000;
</code></pre>



<a name="0x1_validator_MAX_VALIDATOR_SET_SIZE"></a>

Limit the maximum size to u16::max (the current limit of a <code>bitvec</code>).


<pre><code><b>const</b> <a href="validator.md#0x1_validator_MAX_VALIDATOR_SET_SIZE">MAX_VALIDATOR_SET_SIZE</a>: u64 = 65536;
</code></pre>



<a name="0x1_validator_VALIDATOR_STATUS_ACTIVE"></a>



<pre><code><b>const</b> <a href="validator.md#0x1_validator_VALIDATOR_STATUS_ACTIVE">VALIDATOR_STATUS_ACTIVE</a>: u64 = 2;
</code></pre>



<a name="0x1_validator_VALIDATOR_STATUS_INACTIVE"></a>



<pre><code><b>const</b> <a href="validator.md#0x1_validator_VALIDATOR_STATUS_INACTIVE">VALIDATOR_STATUS_INACTIVE</a>: u64 = 4;
</code></pre>



<a name="0x1_validator_VALIDATOR_STATUS_PENDING_ACTIVE"></a>

Validator status enum. We can switch to proper enum later once Move supports it.


<pre><code><b>const</b> <a href="validator.md#0x1_validator_VALIDATOR_STATUS_PENDING_ACTIVE">VALIDATOR_STATUS_PENDING_ACTIVE</a>: u64 = 1;
</code></pre>



<a name="0x1_validator_VALIDATOR_STATUS_PENDING_INACTIVE"></a>



<pre><code><b>const</b> <a href="validator.md#0x1_validator_VALIDATOR_STATUS_PENDING_INACTIVE">VALIDATOR_STATUS_PENDING_INACTIVE</a>: u64 = 3;
</code></pre>



<a name="0x1_validator_initialize_validator_fees"></a>

## Function `initialize_validator_fees`

Initializes the resource storing information about collected transaction fees per validator.
Used by <code><a href="transaction_fee.md#0x1_transaction_fee">transaction_fee</a>.<b>move</b></code> to initialize fee collection and distribution.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="validator.md#0x1_validator_initialize_validator_fees">initialize_validator_fees</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="validator.md#0x1_validator_initialize_validator_fees">initialize_validator_fees</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>) {
    <a href="system_addresses.md#0x1_system_addresses_assert_open_libra">system_addresses::assert_open_libra</a>(open_libra);
    <b>assert</b>!(
        !<b>exists</b>&lt;<a href="validator.md#0x1_validator_ValidatorFees">ValidatorFees</a>&gt;(@open_libra),
        <a href="../../std/doc/error.md#0x1_error_already_exists">error::already_exists</a>(<a href="validator.md#0x1_validator_EFEES_TABLE_ALREADY_EXISTS">EFEES_TABLE_ALREADY_EXISTS</a>)
    );
    <b>move_to</b>(open_libra, <a href="validator.md#0x1_validator_ValidatorFees">ValidatorFees</a> { fees_table: <a href="../../std/doc/table.md#0x1_table_new">table::new</a>() });
}
</code></pre>



</details>

<a name="0x1_validator_add_transaction_fee"></a>

## Function `add_transaction_fee`

Stores the transaction fee collected to the specified validator address.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="validator.md#0x1_validator_add_transaction_fee">add_transaction_fee</a>(validator_addr: <b>address</b>, fee: <a href="coin.md#0x1_coin_Coin">coin::Coin</a>&lt;<a href="ol_coin.md#0x1_ol_coin_OLCoin">ol_coin::OLCoin</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="validator.md#0x1_validator_add_transaction_fee">add_transaction_fee</a>(validator_addr: <b>address</b>, fee: Coin&lt;OLCoin&gt;) <b>acquires</b> <a href="validator.md#0x1_validator_ValidatorFees">ValidatorFees</a> {
    <b>let</b> fees_table = &<b>mut</b> <b>borrow_global_mut</b>&lt;<a href="validator.md#0x1_validator_ValidatorFees">ValidatorFees</a>&gt;(@open_libra).fees_table;
    <b>if</b> (<a href="../../std/doc/table.md#0x1_table_contains">table::contains</a>(fees_table, validator_addr)) {
        <b>let</b> collected_fee = <a href="../../std/doc/table.md#0x1_table_borrow_mut">table::borrow_mut</a>(fees_table, validator_addr);
        <a href="coin.md#0x1_coin_merge">coin::merge</a>(collected_fee, fee);
    } <b>else</b> {
        <a href="../../std/doc/table.md#0x1_table_add">table::add</a>(fees_table, validator_addr, fee);
    }
}
</code></pre>



</details>

<a name="0x1_validator_initialize"></a>

## Function `initialize`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="validator.md#0x1_validator_initialize">initialize</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="validator.md#0x1_validator_initialize">initialize</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>) {
	<a href="system_addresses.md#0x1_system_addresses_assert_open_libra">system_addresses::assert_open_libra</a>(open_libra);

    <b>move_to</b>(open_libra, <a href="validator.md#0x1_validator_ValidatorSet">ValidatorSet</a> {
        consensus_scheme: 0,
        active_validators: <a href="../../std/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        pending_active: <a href="../../std/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        pending_inactive: <a href="../../std/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
        total_voting_power: 0,
        total_joining_power: 0,
    });

    <b>move_to</b>(open_libra, <a href="validator.md#0x1_validator_ValidatorPerformance">ValidatorPerformance</a> {
        validators: <a href="../../std/doc/vector.md#0x1_vector_empty">vector::empty</a>(),
    });
}
</code></pre>



</details>

<a name="0x1_validator_store_ol_coin_mint_cap"></a>

## Function `store_ol_coin_mint_cap`

This is only called during Genesis, which is where MintCapability<OLCoin> can be created.
Beyond genesis, no one can create OLCoin mint/burn capabilities.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="validator.md#0x1_validator_store_ol_coin_mint_cap">store_ol_coin_mint_cap</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, mint_cap: <a href="coin.md#0x1_coin_MintCapability">coin::MintCapability</a>&lt;<a href="ol_coin.md#0x1_ol_coin_OLCoin">ol_coin::OLCoin</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="validator.md#0x1_validator_store_ol_coin_mint_cap">store_ol_coin_mint_cap</a>(open_libra: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, mint_cap: MintCapability&lt;OLCoin&gt;) {
    <a href="system_addresses.md#0x1_system_addresses_assert_open_libra">system_addresses::assert_open_libra</a>(open_libra);
    <b>move_to</b>(open_libra, <a href="validator.md#0x1_validator_OLCoinCapabilities">OLCoinCapabilities</a> { mint_cap })
}
</code></pre>



</details>

<a name="0x1_validator_initialize_validator"></a>

## Function `initialize_validator`

Initialize the validator account and give ownership to the signing account.


<pre><code><b>public</b> entry <b>fun</b> <a href="validator.md#0x1_validator_initialize_validator">initialize_validator</a>(<a href="account.md#0x1_account">account</a>: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>, consensus_pubkey: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, proof_of_possession: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, network_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;, fullnode_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="validator.md#0x1_validator_initialize_validator">initialize_validator</a>(
    <a href="account.md#0x1_account">account</a>: &<a href="../../std/doc/signer.md#0x1_signer">signer</a>,
    consensus_pubkey: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    proof_of_possession: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    network_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    fullnode_addresses: <a href="../../std/doc/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
) { //<b>acquires</b> AllowedValidators {
    // Checks the <b>public</b> key <b>has</b> a valid proof-of-possession <b>to</b> prevent rogue-key attacks.
    <b>let</b> pubkey_from_pop = &<b>mut</b> <a href="../../std/doc/bls12381.md#0x1_bls12381_public_key_from_bytes_with_pop">bls12381::public_key_from_bytes_with_pop</a>(
        consensus_pubkey,
        &proof_of_possession_from_bytes(proof_of_possession)
    );
    <b>assert</b>!(<a href="../../std/doc/option.md#0x1_option_is_some">option::is_some</a>(pubkey_from_pop), <a href="../../std/doc/error.md#0x1_error_invalid_argument">error::invalid_argument</a>(<a href="validator.md#0x1_validator_EINVALID_PUBLIC_KEY">EINVALID_PUBLIC_KEY</a>));

	// 0L-TODO: initialize_owner(<a href="account.md#0x1_account">account</a>);

    <b>move_to</b>(<a href="account.md#0x1_account">account</a>, <a href="validator.md#0x1_validator_ValidatorConfig">ValidatorConfig</a> {
        consensus_pubkey,
        network_addresses,
        fullnode_addresses,
        validator_index: 0,
    });
}
</code></pre>



</details>


[move-book]: https://move-language.github.io/move/introduction.html
