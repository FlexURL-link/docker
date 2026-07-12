CREATE TABLE IF NOT EXISTS redirects (
    id TEXT PRIMARY KEY,
    url TEXT NOT NULL,
    version TEXT DEFAULT 'lite',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);
