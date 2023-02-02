// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

pub use ol_gas_algebra_ext::{
    AbstractValueSize, AbstractValueSizePerArg, AbstractValueUnit, InternalGasPerAbstractValueUnit,
};
use move_core_types::gas_algebra::{GasQuantity, InternalGasUnit, UnitDiv};

/// Unit of (external) gas.
pub enum GasUnit {}

/// Unit of gas currency. 1 Octa = 10^-8 0L coins.
pub enum Octa {}

pub type Gas = GasQuantity<GasUnit>;

pub type GasScalingFactor = GasQuantity<UnitDiv<InternalGasUnit, GasUnit>>;

pub type Fee = GasQuantity<Octa>;

pub type FeePerGasUnit = GasQuantity<UnitDiv<Octa, GasUnit>>;
