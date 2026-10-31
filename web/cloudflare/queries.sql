-- Queries for the unique player count. Paste one into the D1 console
-- (Storage & databases > D1 SQLite Database > strive-stats > Console), or run:
-- wrangler d1 execute strive-stats --remote --command "<query>"

-- Unique players overall.
SELECT COUNT(DISTINCT player_id) AS unique_players FROM visits;

-- Per day: players who opened the game, and how many of them were new.
SELECT visits.day, COUNT(*) AS players, SUM(visits.day = firsts.first_day) AS new_players
FROM visits
JOIN (SELECT player_id, MIN(day) AS first_day FROM visits GROUP BY player_id) AS firsts USING (player_id)
GROUP BY visits.day
ORDER BY visits.day DESC;

-- Unique players by country and by source.
SELECT country, COUNT(DISTINCT player_id) AS players FROM visits GROUP BY country ORDER BY players DESC;
SELECT source, COUNT(DISTINCT player_id) AS players FROM visits GROUP BY source ORDER BY players DESC;
