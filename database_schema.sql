-- SaaradhiGO Driver App — Production PostgreSQL Schema
-- Run this for direct PostgreSQL setup (or use Prisma migrations)
-- Requires PostGIS extension for geo queries

-- ─── Enable Extensions ─────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- ─── Enums ─────────────────────────────────────────────────────────────────

CREATE TYPE driver_status AS ENUM ('PENDING', 'VERIFYING', 'APPROVED', 'SUSPENDED', 'REJECTED');
CREATE TYPE ride_status AS ENUM ('REQUESTED', 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
CREATE TYPE document_type AS ENUM ('LICENSE', 'RC', 'INSURANCE', 'AADHAR', 'PROFILE_PHOTO');
CREATE TYPE document_status AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');
CREATE TYPE transaction_type AS ENUM ('CREDIT', 'DEBIT');
CREATE TYPE payout_status AS ENUM ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED');

-- ─── Users Table ───────────────────────────────────────────────────────────

CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone       VARCHAR(20) UNIQUE NOT NULL,
    role        VARCHAR(20) DEFAULT 'DRIVER',
    created_at  TIMESTAMP DEFAULT NOW(),
    updated_at  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);

-- ─── Drivers Table ─────────────────────────────────────────────────────────

CREATE TABLE drivers (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Profile
    full_name           VARCHAR(100),
    profile_pic         TEXT,       -- S3 URL
    date_of_birth       DATE,
    gender              VARCHAR(10),

    -- Status
    status              driver_status DEFAULT 'PENDING',
    is_online           BOOLEAN DEFAULT FALSE,
    is_on_break         BOOLEAN DEFAULT FALSE,

    -- Location (PostGIS for geo queries)
    current_lat         DECIMAL(10, 8),
    current_lng         DECIMAL(11, 8),
    location            GEOGRAPHY(POINT, 4326),  -- PostGIS column
    last_active_time    TIMESTAMP DEFAULT NOW(),

    -- Vehicle
    vehicle_type        VARCHAR(20),  -- AUTO, SEDAN, SUV
    vehicle_model       VARCHAR(100),
    vehicle_number      VARCHAR(20) UNIQUE,
    vehicle_color       VARCHAR(50),
    vehicle_capacity    INT,

    -- Performance Metrics
    rating              DECIMAL(3,2) DEFAULT 5.00,
    total_rides         INT DEFAULT 0,
    total_distance_km   DECIMAL(10, 2) DEFAULT 0.0,
    cancellation_rate   DECIMAL(5, 2) DEFAULT 0.0,
    acceptance_rate     DECIMAL(5, 2) DEFAULT 100.0,

    -- Finance
    wallet_balance      DECIMAL(12, 2) DEFAULT 0.0,
    total_earnings      DECIMAL(12, 2) DEFAULT 0.0,
    bank_account_no     VARCHAR(20),  -- Encryt in production!
    bank_ifsc           VARCHAR(15),
    upi_id              VARCHAR(100),

    -- Fraud Detection
    is_flagged          BOOLEAN DEFAULT FALSE,
    flag_reason         TEXT,

    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- PostGIS spatial index for fast nearby driver queries
CREATE INDEX idx_drivers_location ON drivers USING GIST(location);
CREATE INDEX idx_drivers_status ON drivers(status);
CREATE INDEX idx_drivers_is_online ON drivers(is_online);

-- ─── Find Nearby Drivers Function (PostGIS) ────────────────────────────────
-- Usage: SELECT * FROM find_nearby_drivers(-78.3915, 17.4448, 5000)
CREATE OR REPLACE FUNCTION find_nearby_drivers(
    pickup_lng DOUBLE PRECISION,
    pickup_lat DOUBLE PRECISION,
    radius_meters INT DEFAULT 5000
)
RETURNS TABLE (
    driver_id UUID,
    full_name VARCHAR,
    distance_meters FLOAT,
    current_lat DECIMAL,
    current_lng DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id,
        d.full_name,
        ST_Distance(
            d.location::geography,
            ST_SetSRID(ST_Point(pickup_lng, pickup_lat), 4326)::geography
        ) AS distance_meters,
        d.current_lat,
        d.current_lng
    FROM drivers d
    WHERE
        d.is_online = TRUE
        AND d.status = 'APPROVED'
        AND d.is_flagged = FALSE
        AND ST_DWithin(
            d.location::geography,
            ST_SetSRID(ST_Point(pickup_lng, pickup_lat), 4326)::geography,
            radius_meters
        )
    ORDER BY distance_meters ASC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- ─── Documents Table ───────────────────────────────────────────────────────

CREATE TABLE documents (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id        UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    type             document_type NOT NULL,
    url              TEXT NOT NULL,      -- S3 URL
    status           document_status DEFAULT 'PENDING',
    rejection_reason TEXT,
    expiry_date      DATE,
    created_at       TIMESTAMP DEFAULT NOW(),
    updated_at       TIMESTAMP DEFAULT NOW()
);

-- ─── Rides Table ───────────────────────────────────────────────────────────

CREATE TABLE rides (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id       UUID REFERENCES drivers(id),
    rider_id        VARCHAR(100) NOT NULL,

    -- Pickup
    pickup_lat      DECIMAL(10, 8) NOT NULL,
    pickup_lng      DECIMAL(11, 8) NOT NULL,
    pickup_addr     TEXT NOT NULL,
    pickup_location GEOGRAPHY(POINT, 4326),

    -- Drop
    drop_lat        DECIMAL(10, 8) NOT NULL,
    drop_lng        DECIMAL(11, 8) NOT NULL,
    drop_addr       TEXT NOT NULL,

    -- Trip Details
    status          ride_status DEFAULT 'REQUESTED',
    fare            DECIMAL(8, 2) NOT NULL,
    distance_km     DECIMAL(6, 2),
    duration_min    INT,
    payment_mode    VARCHAR(20) DEFAULT 'CASH',
    ride_pin        CHAR(4),

    -- Timing
    requested_at    TIMESTAMP DEFAULT NOW(),
    accepted_at     TIMESTAMP,
    arrived_at      TIMESTAMP,
    start_time      TIMESTAMP,
    end_time        TIMESTAMP,

    -- Cancellation
    cancelled_by    VARCHAR(10),    -- 'DRIVER' or 'RIDER'
    cancel_reason   TEXT,

    -- Ratings
    rider_rating_for_driver DECIMAL(2,1),
    driver_rating_for_rider DECIMAL(2,1),

    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_rides_driver_id ON rides(driver_id);
CREATE INDEX idx_rides_status ON rides(status);
CREATE INDEX idx_rides_created_at ON rides(created_at DESC);
CREATE INDEX idx_rides_pickup_location ON rides USING GIST(pickup_location);

-- ─── Earnings Table ────────────────────────────────────────────────────────

CREATE TABLE earnings (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id   UUID NOT NULL REFERENCES drivers(id),
    ride_id     UUID UNIQUE NOT NULL REFERENCES rides(id),
    gross_fare  DECIMAL(8, 2) NOT NULL,
    commission  DECIMAL(8, 2) NOT NULL,
    amount      DECIMAL(8, 2) NOT NULL,  -- Net earnings
    date        TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_earnings_driver_id ON earnings(driver_id);
CREATE INDEX idx_earnings_date ON earnings(date DESC);

-- ─── Transactions Table ────────────────────────────────────────────────────

CREATE TABLE transactions (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id    UUID NOT NULL REFERENCES drivers(id),
    amount       DECIMAL(10, 2) NOT NULL,   -- Positive = credit, Negative = debit
    type         transaction_type NOT NULL,
    description  TEXT,
    reference_id UUID,      -- ride_id or payout_id
    created_at   TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_transactions_driver_id ON transactions(driver_id);

-- ─── Payouts Table ─────────────────────────────────────────────────────────

CREATE TABLE payouts (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id           UUID NOT NULL REFERENCES drivers(id),
    amount              DECIMAL(10, 2) NOT NULL,
    status              payout_status DEFAULT 'PENDING',
    upi_id              VARCHAR(100),
    bank_account        VARCHAR(20),
    gateway_payout_id   VARCHAR(100),   -- Razorpay payout ID
    failure_reason      TEXT,
    requested_at        TIMESTAMP DEFAULT NOW(),
    processed_at        TIMESTAMP,
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- ─── Rider Reports Table (FR-D23) ───────────────────────────────────────────

CREATE TYPE rider_report_severity AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
CREATE TYPE rider_report_status AS ENUM ('PENDING', 'REVIEWED', 'RESOLVED', 'DISMISSED');

CREATE TABLE rider_reports (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id        UUID NOT NULL REFERENCES drivers(id),
    ride_id          UUID REFERENCES rides(id),
    reason           VARCHAR(100) NOT NULL,  -- e.g., 'HARASSMENT', 'SAFETY_CONCERN', 'PAYMENT_ISSUE'
    description      TEXT,
    severity         rider_report_severity DEFAULT 'MEDIUM',
    latitude         DECIMAL(10, 8),
    longitude        DECIMAL(11, 8),
    status           rider_report_status DEFAULT 'PENDING',
    admin_notes      TEXT,
    reviewed_by      UUID,  -- admin user id
    reviewed_at      TIMESTAMP,
    created_at       TIMESTAMP DEFAULT NOW(),
    updated_at       TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_rider_reports_driver_id ON rider_reports(driver_id);
CREATE INDEX idx_rider_reports_ride_id ON rider_reports(ride_id);
CREATE INDEX idx_rider_reports_status ON rider_reports(status);

-- ─── Trigger: Update driver location GEOGRAPHY when lat/lng changes ────────

CREATE OR REPLACE FUNCTION update_driver_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_lat IS NOT NULL AND NEW.current_lng IS NOT NULL THEN
        NEW.location = ST_SetSRID(ST_Point(NEW.current_lng, NEW.current_lat), 4326)::geography;
    END IF;
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER driver_location_trigger
    BEFORE UPDATE ON drivers
    FOR EACH ROW
    EXECUTE FUNCTION update_driver_location();

-- ─── Trigger: updated_at auto-update ─────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_rides_updated_at BEFORE UPDATE ON rides FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_payouts_updated_at BEFORE UPDATE ON payouts FOR EACH ROW EXECUTE FUNCTION set_updated_at();
