// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

use ol_types::account_config::CORE_CODE_ADDRESS;
use move_core_types::{ident_str, identifier::IdentStr, language_storage::ModuleId};
use once_cell::sync::Lazy;

pub(crate) const AGGREGATOR_MODULE_IDENTIFIER: &IdentStr = ident_str!("aggregator");
pub(crate) static AGGREGATOR_MODULE: Lazy<ModuleId> =
    Lazy::new(|| ModuleId::new(CORE_CODE_ADDRESS, AGGREGATOR_MODULE_IDENTIFIER.to_owned()));
