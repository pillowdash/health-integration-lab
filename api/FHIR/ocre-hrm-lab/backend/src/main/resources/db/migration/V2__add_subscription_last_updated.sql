
-- V2: Add last-updated timestamp to physician subscriptions

ALTER TABLE physician_subscriptions
ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

