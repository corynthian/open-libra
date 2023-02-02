// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

use anyhow::Result;
use ol_gas::gen::{generate_update_proposal, GenArgs};
use clap::Parser;

fn main() -> Result<()> {
    let args = GenArgs::parse();

    generate_update_proposal(&args)
}
