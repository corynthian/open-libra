// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

// 0L-TODO: Questionable renamings ... Investigate effect of changing these.

// pub use move_core_types::vm_status::known_locations::{
//     CORE_ACCOUNT_MODULE, CORE_ACCOUNT_MODULE_IDENTIFIER,
//     DIEM_ACCOUNT_MODULE as OL_ACCOUNT_MODULE,
//     DIEM_ACCOUNT_MODULE_IDENTIFIER as OL_ACCOUNT_MODULE_IDENTIFIER,
// };

use move_core_types::{
    ident_str, identifier::IdentStr, language_storage::{ModuleId, CORE_CODE_ADDRESS},
};
use once_cell::sync::Lazy;

pub const CORE_ACCOUNT_MODULE_IDENTIFIER: &IdentStr = ident_str!("account");
pub static CORE_ACCOUNT_MODULE: Lazy<ModuleId> =
    Lazy::new(|| ModuleId::new(CORE_CODE_ADDRESS, CORE_ACCOUNT_MODULE_IDENTIFIER.to_owned()));

pub const OL_ACCOUNT_MODULE_IDENTIFIER: &IdentStr = ident_str!("ol_account");
pub static OL_ACCOUNT_MODULE: Lazy<ModuleId> =
    Lazy::new(|| ModuleId::new(CORE_CODE_ADDRESS, OL_ACCOUNT_MODULE_IDENTIFIER.to_owned()));

