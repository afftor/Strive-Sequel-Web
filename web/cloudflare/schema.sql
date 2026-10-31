-- Unique players of the web build: one row per browser per day, written by
-- functions/api/stats.js.
-- Apply with: wrangler d1 execute strive-stats --remote --file schema.sql
CREATE TABLE IF NOT EXISTS visits (
	-- UTC date, YYYY-MM-DD.
	day TEXT NOT NULL,
	-- Random ID kept in the browser's localStorage; identifies a browser, not a person.
	player_id TEXT NOT NULL,
	country TEXT,
	-- Host of the referring page, or 'direct'.
	source TEXT,
	PRIMARY KEY (day, player_id)
);
