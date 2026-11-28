
-- Up Migration

-- ==========================================
-- 1. USERS
-- ==========================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    password_hash TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_user_name
        CHECK (length(trim(name)) > 0),

    CONSTRAINT uq_users_email
        UNIQUE (email),

    CONSTRAINT uq_users_phone_number
        UNIQUE (phone_number)
);

-- ==========================================
-- 2. MOVIES
-- ==========================================

CREATE TABLE movies (
    id BIGSERIAL PRIMARY KEY,

    title VARCHAR(255) NOT NULL,

    duration_min INTEGER NOT NULL
        CHECK (duration_min > 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ==========================================
-- 3. SHOWS
-- ==========================================

CREATE TABLE shows (
    id BIGSERIAL PRIMARY KEY,

    movie_id BIGINT NOT NULL
        REFERENCES movies(id),

    starts_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_shows_movie_start
ON shows(movie_id, starts_at);


-- ==========================================
-- 4. SHOW SEATS
-- ==========================================

CREATE TABLE show_seats (
    id BIGSERIAL PRIMARY KEY,

    show_id BIGINT NOT NULL
        REFERENCES shows(id),

    seat_label TEXT NOT NULL,

    status TEXT NOT NULL DEFAULT 'AVAILABLE'
        CHECK (status IN ('AVAILABLE', 'BOOKED')),

    price_paise BIGINT NOT NULL
        CHECK (price_paise >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_show_seat_label
        UNIQUE (show_id, seat_label)
);

CREATE INDEX idx_show_seats_status
ON show_seats(show_id, status);


-- ==========================================
-- 5. BOOKINGS
-- ==========================================

CREATE TABLE bookings (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL
        REFERENCES users(id) ON DELETE RESTRICT,

    status TEXT NOT NULL DEFAULT 'PENDING'
        CHECK (
            status IN (
                'PENDING',
                'CONFIRMED',
                'EXPIRED',
                'REFUND_NEEDED'
            )
        ),

    total_amount_paise BIGINT NOT NULL
        CHECK (total_amount_paise >= 0),

    expires_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bookings_user
ON bookings(user_id, created_at DESC);

CREATE INDEX idx_bookings_pending_expiry
ON bookings(expires_at)
WHERE status = 'PENDING';


-- ==========================================
-- 6. BOOKING SEATS
-- ==========================================

CREATE TABLE booking_seats (
    booking_id BIGINT NOT NULL
        REFERENCES bookings(id) ON DELETE CASCADE,

    show_seat_id BIGINT NOT NULL
        REFERENCES show_seats(id),

    price_paise BIGINT NOT NULL
        CHECK (price_paise >= 0),

    PRIMARY KEY (booking_id, show_seat_id),

    CONSTRAINT uq_booking_show_seat
        UNIQUE (show_seat_id)
);


-- ==========================================
-- 7. PAYMENTS
-- ==========================================

CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,

    booking_id BIGINT NOT NULL
        REFERENCES bookings(id),

    amount_paise BIGINT NOT NULL
        CHECK (amount_paise >= 0),

    provider_event_id TEXT NOT NULL,

    status TEXT NOT NULL
        CHECK (status IN ('SUCCESS', 'FAILED')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_payment_provider_event
        UNIQUE (provider_event_id)
);

CREATE INDEX idx_payments_booking
ON payments(booking_id);


-- Down Migration

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS booking_seats;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS show_seats;
DROP TABLE IF EXISTS shows;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS users;
