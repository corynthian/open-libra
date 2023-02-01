// Copyright (c) 0L
// SPDX-License-Identifier: Apache-2.0

//! Logging metrics for determining quality of log submission
use once_cell::sync::Lazy;
use prometheus::{register_int_counter, IntCounter};

/// Count of the struct logs submitted by macro
pub static STRUCT_LOG_COUNT: Lazy<IntCounter> = Lazy::new(|| {
    register_int_counter!("ol_struct_log_count", "Count of the struct logs.").unwrap()
});

/// Count of struct logs processed, but not necessarily sent
pub static PROCESSED_STRUCT_LOG_COUNT: Lazy<IntCounter> = Lazy::new(|| {
    register_int_counter!(
        "ol_struct_log_processed_count",
        "Count of the struct logs received by the sender."
    )
    .unwrap()
});

/// Metric for when we fail to log during sending to the queue
pub static STRUCT_LOG_QUEUE_ERROR_COUNT: Lazy<IntCounter> = Lazy::new(|| {
    register_int_counter!(
        "ol_struct_log_queue_error_count",
        "Count of all errors during queuing struct logs."
    )
    .unwrap()
});

pub static STRUCT_LOG_PARSE_ERROR_COUNT: Lazy<IntCounter> = Lazy::new(|| {
    register_int_counter!(
        "ol_struct_log_parse_error_count",
        "Count of all parse errors during struct logs."
    )
    .unwrap()
});

/// Counter for failed log ingest writes (see also: ol-telemetry for sender metrics)
pub static OL_LOG_INGEST_WRITER_FULL: Lazy<IntCounter> = Lazy::new(|| {
    register_int_counter!(
        "ol_log_ingest_writer_full",
        "Number of log ingest writes that failed due to channel full"
    )
    .unwrap()
});

/// Counter for failed log ingest writes (see also: ol-telemetry for sender metrics)
pub static OL_LOG_INGEST_WRITER_DISCONNECTED: Lazy<IntCounter> = Lazy::new(|| {
    register_int_counter!(
        "ol_log_ingest_writer_disconnected",
        "Number of log ingest writes that failed due to channel disconnected"
    )
    .unwrap()
});