spec open_libra::storage_gas {
    // -----------------
    // Struct invariants
    // -----------------

    spec Point {
        invariant x <= BASIS_POINT_DENOMINATION;
        invariant y <= BASIS_POINT_DENOMINATION;
    }

    spec GasCurve {
        invariant min_gas <= max_gas;
        invariant max_gas <= MAX_U64 / BASIS_POINT_DENOMINATION;
        invariant (len(points) > 0 ==> points[0].x > 0)
            && (len(points) > 0 ==> points[len(points) - 1].x < BASIS_POINT_DENOMINATION)
            && (forall i in 0..len(points) - 1: (points[i].x < points[i + 1].x && points[i].y <= points[i + 1].y));
    }

    spec UsageGasConfig {
        invariant target_usage > 0;
        invariant target_usage <= MAX_U64 / BASIS_POINT_DENOMINATION;
    }


    // -----------------
    // Global invariants
    // -----------------

    spec module {
        use std::chain_status;
        pragma verify = true;
        pragma aborts_if_is_strict;
        // After genesis, `StateStorageUsage` and `GasParameter` exist.
        invariant [suspendable] chain_status::is_operating() ==> exists<StorageGasConfig>(@open_libra);
        invariant [suspendable] chain_status::is_operating() ==> exists<StorageGas>(@open_libra);
    }


    // -----------------------
    // Function specifications
    // -----------------------

    spec base_8192_exponential_curve(min_gas: u64, max_gas: u64): GasCurve {
        include NewGasCurveAbortsIf;
    }

    spec new_point(x: u64, y: u64): Point {
        aborts_if x > BASIS_POINT_DENOMINATION || y > BASIS_POINT_DENOMINATION;

        ensures result.x == x;
        ensures result.y == y;
    }

    /// A non decreasing curve must ensure that next is greater than cur.
    spec new_gas_curve(min_gas: u64, max_gas: u64, points: vector<Point>): GasCurve {
        include NewGasCurveAbortsIf;
        include ValidatePointsAbortsIf;
    }

    spec new_usage_gas_config(target_usage: u64, read_curve: GasCurve, create_curve: GasCurve, write_curve: GasCurve): UsageGasConfig {
        aborts_if target_usage == 0;
        aborts_if target_usage > MAX_U64 / BASIS_POINT_DENOMINATION;
    }

    spec new_storage_gas_config(item_config: UsageGasConfig, byte_config: UsageGasConfig): StorageGasConfig {
        aborts_if false;

        ensures result.item_config == item_config;
        ensures result.byte_config == byte_config;
    }

    /// Signer address must be @open_libra and StorageGasConfig exists.
    spec set_config(open_libra: &signer, config: StorageGasConfig) {
        include system_addresses::AbortsIfNotOpenLibra{ account: open_libra };
        aborts_if !exists<StorageGasConfig>(@open_libra);
    }

    /// Signer address must be @open_libra.
    /// Address @open_libra does not exist StorageGasConfig and StorageGas before the function call is restricted
    /// and exists after the function is executed.
    spec initialize(open_libra: &signer) {
        include system_addresses::AbortsIfNotOpenLibra{ account: open_libra };
        aborts_if exists<StorageGasConfig>(@open_libra);
        aborts_if exists<StorageGas>(@open_libra);

        ensures exists<StorageGasConfig>(@open_libra);
        ensures exists<StorageGas>(@open_libra);
    }

    /// A non decreasing curve must ensure that next is greater than cur.
    spec validate_points(points: &vector<Point>) {
        pragma aborts_if_is_strict = false;
        pragma opaque;
        include ValidatePointsAbortsIf;
    }

    spec calculate_gas(max_usage: u64, current_usage: u64, curve: &GasCurve): u64 {
        pragma opaque;
        requires max_usage > 0;
        requires max_usage <= MAX_U64 / BASIS_POINT_DENOMINATION;
        aborts_if false;
        ensures [abstract] result == spec_calculate_gas(max_usage, current_usage, curve);
    }

    spec interpolate(x0: u64, x1: u64, y0: u64, y1: u64, x: u64): u64 {
        pragma opaque;
        pragma intrinsic;

        aborts_if false;
    }

    /// Address @open_libra must exist StorageGasConfig and StorageGas and StateStorageUsage.
    spec on_reconfig {
        use std::chain_status;
        requires chain_status::is_operating();
        aborts_if !exists<StorageGasConfig>(@open_libra);
        aborts_if !exists<StorageGas>(@open_libra);
        aborts_if !exists<state_storage::StateStorageUsage>(@open_libra);
    }


    // ---------------------------------
    // Spec helper functions and schemas
    // ---------------------------------

    spec fun spec_calculate_gas(max_usage: u64, current_usage: u64, curve: GasCurve): u64;

    spec schema NewGasCurveAbortsIf {
        min_gas: u64;
        max_gas: u64;

        aborts_if max_gas < min_gas;
        aborts_if max_gas > MAX_U64 / BASIS_POINT_DENOMINATION;
    }

    /// A non decreasing curve must ensure that next is greater than cur.
    spec schema ValidatePointsAbortsIf {
        points: vector<Point>;

        aborts_if exists i in 0..len(points) - 1: (
            points[i].x >= points[i + 1].x || points[i].y > points[i + 1].y
        );
        aborts_if len(points) > 0 && points[0].x == 0;
        aborts_if len(points) > 0 && points[len(points) - 1].x == BASIS_POINT_DENOMINATION;
    }
}
