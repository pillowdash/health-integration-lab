
-- V1: Initial persistent OCRE/HRM lab schema
-- Synthetic healthcare data only

CREATE TABLE clinical_reports (
    id UUID PRIMARY KEY,
    message_control_id VARCHAR(255) NOT NULL UNIQUE,
    mrn VARCHAR(128) NOT NULL,
    patient_name TEXT,
    physician_id VARCHAR(128) NOT NULL,
    report_code VARCHAR(64) NOT NULL,
    report_text TEXT,
    fhir_bundle JSONB,
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_report_mrn
        CHECK (LENGTH(BTRIM(mrn)) > 0)
);

CREATE TABLE physician_subscriptions (
    id VARCHAR(128) PRIMARY KEY,
    physician_id VARCHAR(128) NOT NULL,
    report_code VARCHAR(64) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'requested',
    fhir_resource JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE report_deliveries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    report_id UUID NOT NULL
        REFERENCES clinical_reports(id),
    subscription_id VARCHAR(128) NOT NULL
        REFERENCES physician_subscriptions(id),
    physician_id VARCHAR(128) NOT NULL,
    report_code VARCHAR(64) NOT NULL,
    delivered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_report_subscription
        UNIQUE (report_id, subscription_id)
);

CREATE INDEX idx_reports_physician_code
    ON clinical_reports(physician_id, report_code);

CREATE INDEX idx_subscriptions_physician_code
    ON physician_subscriptions(physician_id, report_code);

CREATE INDEX idx_deliveries_report
    ON report_deliveries(report_id);

