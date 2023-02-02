spec open_libra::block {
    spec module {
        use std::chain_status;
        // After genesis, `BlockResource` exist.
        invariant [suspendable] chain_status::is_operating() ==> exists<BlockResource>(@open_libra);
    }

    spec block_prologue {
        use open_libra::chain_status;
        use open_libra::coin::CoinInfo;
        use open_libra::ol_coin::OLCoin;
        requires chain_status::is_operating();
        requires system_addresses::is_vm(vm);
	// 0L-TODO
        requires proposer == @vm_reserved /* || stake::spec_is_current_epoch_validator(proposer) */;
        requires timestamp >= reconfiguration::last_reconfiguration_time();
        requires (proposer == @vm_reserved) ==> (timestamp::spec_now_microseconds() == timestamp);
        requires (proposer != @vm_reserved) ==> (timestamp::spec_now_microseconds() < timestamp);
	// 0L-TODO
        // requires exists<stake::ValidatorFees>(@open_libra);
        requires exists<CoinInfo<OLCoin>>(@open_libra);

        aborts_if false;
    }

    spec emit_genesis_block_event {
        use open_libra::chain_status;

        requires chain_status::is_operating();
        requires system_addresses::is_vm(vm);
        requires event::counter(global<BlockResource>(@open_libra).new_block_events) == 0;
        requires (timestamp::spec_now_microseconds() == 0);

        aborts_if false;
    }

    spec emit_new_block_event {
        use open_libra::chain_status;
        let proposer = new_block_event.proposer;
        let timestamp = new_block_event.time_microseconds;

        requires chain_status::is_operating();
        requires system_addresses::is_vm(vm);
        requires (proposer == @vm_reserved) ==> (timestamp::spec_now_microseconds() == timestamp);
        requires (proposer != @vm_reserved) ==> (timestamp::spec_now_microseconds() < timestamp);
        requires event::counter(event_handle) == new_block_event.height;

        aborts_if false;
    }

    /// The caller is open_libra.
    /// The new_epoch_interval must be greater than 0.
    /// The BlockResource is not under the caller before initializing.
    /// The Account is not under the caller until the BlockResource is created for the caller.
    /// Make sure The BlockResource under the caller existed after initializing.
    /// The number of new events created does not exceed MAX_U64.
    spec initialize(open_libra: &signer, epoch_interval_microsecs: u64) {
        include Initialize;
        include NewEventHandle;
    }

    spec schema Initialize {
        use std::signer;
        open_libra: signer;
        epoch_interval_microsecs: u64;

        let addr = signer::address_of(open_libra);
        aborts_if addr != @open_libra;
        aborts_if epoch_interval_microsecs <= 0;
        aborts_if exists<BlockResource>(addr);
        ensures exists<BlockResource>(addr);
    }

    spec schema NewEventHandle {
        use std::signer;
        open_libra: signer;

        let addr = signer::address_of(open_libra);
        let account = global<account::Account>(addr);
        aborts_if !exists<account::Account>(addr);
        aborts_if account.guid_creation_num + 2 > MAX_U64;
    }

    /// The caller is @open_libra.
    /// The new_epoch_interval must be greater than 0.
    /// The BlockResource existed under the @open_libra.
    spec update_epoch_interval_microsecs(
        open_libra: &signer,
        new_epoch_interval: u64,
    ) {
        include UpdateEpochIntervalMicrosecs;
    }

    spec schema UpdateEpochIntervalMicrosecs {
        use std::signer;
        open_libra: signer;
        new_epoch_interval: u64;

        let addr = signer::address_of(open_libra);

        aborts_if addr != @open_libra;
        aborts_if new_epoch_interval <= 0;
        aborts_if !exists<BlockResource>(addr);
        let post block_resource = global<BlockResource>(addr);
        ensures block_resource.epoch_interval == new_epoch_interval;
    }

    spec get_epoch_interval_secs(): u64 {
        aborts_if !exists<BlockResource>(@open_libra);
    }

    spec get_current_block_height(): u64 {
        aborts_if !exists<BlockResource>(@open_libra);
    }

    /// The caller is @vm_reserved.
    /// The BlockResource existed under the @open_libra.
    /// The Configuration existed under the @open_libra.
    /// The CurrentTimeMicroseconds existed under the @open_libra.
    spec emit_writeset_block_event(vm_signer: &signer, fake_block_hash: address) {
        include EmitWritesetBlockEvent;
    }

    spec schema EmitWritesetBlockEvent {
        use std::signer;
        vm_signer: signer;

        let addr = signer::address_of(vm_signer);
        aborts_if addr != @vm_reserved;
        aborts_if !exists<BlockResource>(@open_libra);
        aborts_if !exists<reconfiguration::Configuration>(@open_libra);
        aborts_if !exists<timestamp::CurrentTimeMicroseconds>(@open_libra);
    }
}
