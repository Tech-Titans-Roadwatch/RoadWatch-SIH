-- RoadWatch PostgreSQL schema
-- NOTE: SQLAlchemy auto-creates this on first backend run via Base.metadata.create_all().
-- This file is for reference, manual setup, or if you prefer raw psql.
--
-- Run manually:
--   psql -U postgres -d roadwatch -f database/1_schema.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE severity_enum  AS ENUM ('Low', 'Medium', 'High');
CREATE TYPE status_enum    AS ENUM (
    'Reported', 'Verified', 'Assigned', 'Repair in Progress', 'Resolved'
);

CREATE TABLE complaints (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    image_url             TEXT NOT NULL,
    latitude              DOUBLE PRECISION NOT NULL,
    longitude             DOUBLE PRECISION NOT NULL,
    description           TEXT,

    -- AI output
    severity              severity_enum,
    ai_confidence         DOUBLE PRECISION,
    detections_count      INTEGER DEFAULT 0,
    ai_summary            TEXT,

    -- Workflow
    status                status_enum DEFAULT 'Reported',
    assigned_department   TEXT DEFAULT 'Unassigned',
    notes                 TEXT,

    -- Duplicate clustering
    cluster_id            UUID,

    -- Push notifications
    reporter_device_token TEXT,

    created_at            TIMESTAMP DEFAULT now(),
    updated_at            TIMESTAMP DEFAULT now()
);

-- Indexes for common query patterns
CREATE INDEX idx_complaints_status   ON complaints(status);
CREATE INDEX idx_complaints_cluster  ON complaints(cluster_id);
CREATE INDEX idx_complaints_location ON complaints(latitude, longitude);
