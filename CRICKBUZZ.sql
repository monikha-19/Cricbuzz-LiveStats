use cricbuzz_db;

 

-- Teams
CREATE TABLE IF NOT EXISTS teams (
    team_id INT AUTO_INCREMENT PRIMARY KEY,
    team_name VARCHAR(100) NOT NULL,
    country VARCHAR(50)
);

-- Players
CREATE TABLE IF NOT EXISTS players (
    player_id INT AUTO_INCREMENT PRIMARY KEY,
    player_name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    playing_role VARCHAR(50),
    batting_style VARCHAR(50),
    bowling_style VARCHAR(50)
);

-- Matches
CREATE TABLE IF NOT EXISTS matches (
    match_id INT AUTO_INCREMENT PRIMARY KEY,
    team1_id INT,
    team2_id INT,
    venue_id INT,
    match_date DATE,
    format VARCHAR(10),
    status VARCHAR(50),
    result VARCHAR(200),
    winner VARCHAR(100),
    toss_winner INT,
    toss_decision VARCHAR(20),
    victory_margin INT,
    victory_type VARCHAR(50),
    FOREIGN KEY (team1_id) REFERENCES teams(team_id),
    FOREIGN KEY (team2_id) REFERENCES teams(team_id),
    FOREIGN KEY (venue_id) REFERENCES venues(venue_id)
);

-- Venues
CREATE TABLE IF NOT EXISTS venues (
    venue_id INT AUTO_INCREMENT PRIMARY KEY,
    venue_name VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    capacity INT
);

-- Batting Stats
CREATE TABLE IF NOT EXISTS batting_stats (
    stat_id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT,
    match_id INT,
    runs INT,
    balls_faced INT,
    batting_average FLOAT,
    strike_rate FLOAT,
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (match_id) REFERENCES matches(match_id)
);

-- Bowling Stats
CREATE TABLE IF NOT EXISTS bowling_stats (
    stat_id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT,
    match_id INT,
    overs FLOAT,
    wickets INT,
    runs_conceded INT,
    economy FLOAT,
    bowling_average FLOAT,
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (match_id) REFERENCES matches(match_id)
);

-- Batting Partnerships
CREATE TABLE IF NOT EXISTS batting_partnerships (
    partnership_id INT AUTO_INCREMENT PRIMARY KEY,
    innings_id INT,
    player1_id INT,
    player2_id INT,
    position1 INT,
    position2 INT,
    runs INT,
    FOREIGN KEY (player1_id) REFERENCES players(player_id),
    FOREIGN KEY (player2_id) REFERENCES players(player_id)
);

-- Fielding Stats
CREATE TABLE IF NOT EXISTS fielding_stats (
    fielding_id INT AUTO_INCREMENT PRIMARY KEY,
    player_id INT,
    match_id INT,
    catches INT,
    run_outs INT,
    stumpings INT,
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (match_id) REFERENCES matches(match_id)
);

-- Series
CREATE TABLE IF NOT EXISTS series (
    series_id INT AUTO_INCREMENT PRIMARY KEY,
    series_name VARCHAR(100),
    host_country VARCHAR(50),
    match_type VARCHAR(10),
    start_date DATE,
    total_matches INT
);

SELECT full_name,
       playing_role,
       batting_style,
       bowling_style
FROM players
WHERE country = 'India';

SHOW COLUMNS FROM players;


-- 1---
SELECT player_name, role
FROM players
WHERE team_id = (
    SELECT team_id FROM teams WHERE country = 'India'
)
LIMIT 1000;

SELECT m.description,
       t1.name AS team1,
       t2.name AS team2,
       v.name AS venue,
       v.city,
       m.match_date
FROM matches m
JOIN teams t1 ON m.team1_id = t1.id
JOIN teams t2 ON m.team2_id = t2.id
JOIN venues v ON m.venue_id = v.id
WHERE m.match_date >= CURRENT_DATE - INTERVAL '30' DAY
ORDER BY m.match_date DESC;

SHOW COLUMNS FROM matches;


SELECT 
    t1.team_name AS team1,
    t2.team_name AS team2,
    v.name AS venue,
    v.city,
    m.match_date,
    m.result
FROM matches m
JOIN teams t1 ON m.team1_id = t1.team_id
JOIN teams t2 ON m.team2_id = t2.team_id
JOIN venues v ON m.venue_id = v.venue_id
WHERE m.match_date >= CURRENT_DATE - INTERVAL 30 DAY
ORDER BY m.match_date DESC
LIMIT 1000;

SHOW COLUMNS FROM venues;

SELECT * FROM teams;


INSERT INTO matches (team1_id, team2_id, venue_id, match_date, result)
VALUES (1, 2, 1, CURRENT_DATE - INTERVAL 5 DAY, 'Team 1 won by 5 wickets');


-- 2--
SELECT 
    t1.team_name AS team1,
    t2.team_name AS team2,
    v.venue_name AS venue,
    v.city,
    m.match_date,
    m.result
FROM matches m
JOIN teams t1 ON m.team1_id = t1.team_id
JOIN teams t2 ON m.team2_id = t2.team_id
JOIN venues v ON m.venue_id = v.venue_id
WHERE m.match_date >= CURRENT_DATE - INTERVAL 30 DAY
ORDER BY m.match_date DESC
LIMIT 1000;

SELECT p.full_name,
       s.runs AS total_runs,
       s.batting_average,
       s.centuries
FROM player_career_stats s
JOIN players p ON s.player_id = p.id
WHERE s.format = 'ODI'
ORDER BY s.runs DESC
LIMIT 10;

SHOW TABLES;

SHOW COLUMNS FROM batting_stats;

ALTER TABLE batting_stats ADD COLUMN batting_average FLOAT;

UPDATE batting_stats
SET batting_average = 58.2
WHERE player_id = 1;


ALTER TABLE batting_stats ADD COLUMN centuries INT;

ALTER TABLE batting_stats ADD COLUMN format VARCHAR(10);

UPDATE batting_stats SET format = 'ODI' WHERE player_id IN (1, 2, 3);



-- 3--
SELECT 
    p.player_name,
    s.runs AS total_runs,
    s.batting_average,
    s.centuries
FROM batting_stats s
JOIN players p ON s.player_id = p.player_id
WHERE s.format = 'ODI'
ORDER BY s.runs DESC
LIMIT 10;


ALTER TABLE venues ADD COLUMN capacity INT;

SET SQL_SAFE_UPDATES = 0;


UPDATE venues SET capacity = 68000 WHERE venue_name = 'Eden Gardens';
UPDATE venues SET capacity = 50000 WHERE venue_name = 'Chepauk Stadium';
UPDATE venues SET capacity = 75000 WHERE venue_name = 'Narendra Modi Stadium';
UPDATE venues SET capacity = 40000 WHERE venue_name = 'Wankhede Stadium';

SELECT venue_name, city, country, capacity
FROM venues
WHERE capacity > 50000
ORDER BY capacity DESC;

SELECT venue_name, capacity FROM venues ORDER BY capacity DESC;

SELECT venue_name, capacity FROM venues WHERE capacity IS NULL;

UPDATE venues SET capacity = 75000 WHERE venue_name = 'MCG';
UPDATE venues SET capacity = 68000 WHERE venue_name = 'Narendra Modi Stadium';
UPDATE venues SET capacity = 62000 WHERE venue_name = 'Eden Gardens';

COMMIT;

-- 4--
SELECT venue_name, city, country, capacity
FROM venues
WHERE capacity > 50000
ORDER BY capacity DESC;

-- 5--
SELECT 
    t.team_name,
    COUNT(*) AS total_wins
FROM matches m
JOIN teams t ON (
    (m.result LIKE '%Team 1 won%' AND m.team1_id = t.team_id) OR
    (m.result LIKE '%Team 2 won%' AND m.team2_id = t.team_id)
)
GROUP BY t.team_name
ORDER BY total_wins DESC;



SHOW COLUMNS FROM players;

-- 6--
SELECT 
    role,
    COUNT(*) AS player_count
FROM players
GROUP BY role
ORDER BY player_count DESC;


UPDATE batting_stats SET format = 'ODI' WHERE match_id IN (1, 2, 3);
UPDATE batting_stats SET format = 'Test' WHERE match_id IN (4, 5);
UPDATE batting_stats SET format = 'T20I' WHERE match_id IN (6, 7);

-- 7--
SELECT 
    format,
    MAX(runs) AS highest_score
FROM batting_stats
GROUP BY format
ORDER BY highest_score DESC;


SELECT 
    tournament_name AS series_name,
    host_country,
    match_type,
    start_date,
    total_matches
FROM tournaments
WHERE YEAR(start_date) = 2024
ORDER BY start_date;

SHOW COLUMNS FROM tournaments;


SELECT 
    name AS series_name,
    year,
    tournament_id
FROM tournaments
WHERE year = 2024
ORDER BY name;


SELECT * FROM tournaments WHERE year = 2024;

UPDATE tournaments 
SET host_country = 'India', match_type = 'Test', total_matches = 5 
WHERE name = 'Border-Gavaskar Trophy' AND year = 2024;

UPDATE tournaments 
SET host_country = 'Australia', match_type = 'ODI', total_matches = 3 
WHERE name = 'Australia vs England Series' AND year = 2024;

ALTER TABLE tournaments 
ADD COLUMN host_country VARCHAR(50),
ADD COLUMN match_type VARCHAR(10),
ADD COLUMN total_matches INT;


UPDATE tournaments  
SET host_country = 'India', 
    match_type = 'Test', 
    total_matches = 5  
WHERE name = 'Border-Gavaskar Trophy' AND year = 2024;

INSERT INTO tournaments (name, year, host_country, match_type, total_matches)
VALUES ('Border-Gavaskar Trophy', 2024, 'India', 'Test', 5);

-- 8--
SELECT 
    name AS series_name,
    host_country,
    match_type,
    year,
    total_matches
FROM tournaments
WHERE year = 2024
ORDER BY name;


SELECT 
    p.player_name,
    b.format,
    SUM(b.runs) AS total_runs,
    SUM(w.wickets) AS total_wickets
FROM players p
JOIN batting_stats b ON p.player_id = b.player_id
JOIN bowling_stats w ON p.player_id = w.player_id AND b.format = w.format
WHERE b.runs > 1000 AND w.wickets > 50
GROUP BY p.player_name, b.format
ORDER BY total_runs DESC, total_wickets DESC;

ALTER TABLE bowling_stats ADD COLUMN format VARCHAR(10);

UPDATE bowling_stats SET format = 'ODI' WHERE match_id IN (1, 2, 3);
UPDATE bowling_stats SET format = 'Test' WHERE match_id IN (4, 5);
UPDATE bowling_stats SET format = 'T20I' WHERE match_id IN (6, 7);

UPDATE batting_stats SET runs = 1200 WHERE player_id = 1;
UPDATE bowling_stats SET wickets = 60 WHERE player_id = 1;


 SELECT 
    p.player_name,
    b.format,
    SUM(b.runs) AS total_runs,
    SUM(w.wickets) AS total_wickets
FROM players p
JOIN batting_stats b ON p.player_id = b.player_id
JOIN bowling_stats w ON p.player_id = w.player_id AND b.format = w.format
GROUP BY p.player_name, b.format
HAVING SUM(b.runs) > 100 AND SUM(w.wickets) > 5
ORDER BY total_runs DESC, total_wickets DESC;



SELECT COUNT(*) FROM batting_stats;
SELECT COUNT(*) FROM bowling_stats;

-- Insert into players
INSERT INTO players (player_id, player_name) VALUES (12, 'Ravi Kumar'), (11, 'Arjun Patel');

-- Insert into batting_stats
INSERT INTO batting_stats (player_id, format, runs) VALUES
(12, 'ODI', 1200),
(11, 'ODI', 1100);

-- Insert into bowling_stats
INSERT INTO bowling_stats (player_id, format, wickets) VALUES
(12, 'ODI', 60),
(11, 'ODI', 55);



-- 9--
SELECT 
    p.player_name,
    b.format,
    SUM(b.runs) AS total_runs,
    SUM(w.wickets) AS total_wickets
FROM players p
JOIN batting_stats b ON p.player_id = b.player_id
JOIN bowling_stats w ON p.player_id = w.player_id AND b.format = w.format
WHERE b.runs > 1000 AND w.wickets > 50
GROUP BY p.player_name, b.format
ORDER BY total_runs DESC, total_wickets DESC;



SELECT 
    m.match_description,
    t1.team_name AS team1,
    t2.team_name AS team2,
    tw.team_name AS winning_team,
    m.victory_margin,
    m.victory_type,
    v.venue_name,
    m.match_date
FROM matches m
JOIN teams t1 ON m.team1_id = t1.team_id
JOIN teams t2 ON m.team2_id = t2.team_id
JOIN teams tw ON m.winner_team_id = tw.team_id
JOIN venues v ON m.venue_id = v.venue_id
WHERE m.match_date IS NOT NULL
ORDER BY m.match_date DESC
LIMIT 20


SHOW COLUMNS FROM matches;

-- 10--
SELECT 
    t1.team_name AS team1,
    t2.team_name AS team2,
    m.result,
    v.venue_name,
    m.match_date
FROM matches m
JOIN teams t1 ON m.team1_id = t1.team_id
JOIN teams t2 ON m.team2_id = t2.team_id
JOIN venues v ON m.venue_id = v.venue_id
WHERE m.result IS NOT NULL
ORDER BY m.match_date DESC
LIMIT 20;

UPDATE batting_stats SET format = 'Test', runs = 500 WHERE player_id = 1;
INSERT INTO batting_stats (player_id, format, runs) VALUES (1, 'ODI', 600);
INSERT INTO batting_stats (player_id, format, runs) VALUES (1, 'T20I', 300);

-- 11--
SELECT 
    p.player_name,
    SUM(CASE WHEN b.format = 'Test' THEN b.runs ELSE 0 END) AS test_runs,
    SUM(CASE WHEN b.format = 'ODI' THEN b.runs ELSE 0 END) AS odi_runs,
    SUM(CASE WHEN b.format = 'T20I' THEN b.runs ELSE 0 END) AS t20i_runs
FROM players p
JOIN batting_stats b ON p.player_id = b.player_id
GROUP BY p.player_id, p.player_name
HAVING COUNT(DISTINCT b.format) >= 2
ORDER BY test_runs + odi_runs + t20i_runs DESC;


SELECT 
    t.team_name,
    t.country AS team_country,
    SUM(CASE WHEN t.country = v.venue_country THEN 1 ELSE 0 END) AS home_wins,
    SUM(CASE WHEN t.country != v.venue_country THEN 1 ELSE 0 END) AS away_wins
FROM matches m
JOIN teams t ON m.winner_team_id = t.team_id
JOIN venues v ON m.venue_id = v.venue_id
GROUP BY t.team_id, t.team_name, t.country
ORDER BY home_wins DESC, away_wins DESC;


SHOW COLUMNS FROM venues;

ALTER TABLE matches ADD COLUMN winner_team_id INT;

UPDATE matches SET winner_team_id = 1 WHERE match_id = 101;

-- Add venue
INSERT INTO venues (venue_id, venue_name, city, country, capacity) 
VALUES (101, 'Wankhede Stadium', 'Mumbai', 'India', 33000);

 INSERT INTO teams (team_id, team_name, country) 
VALUES (101, 'India', 'India');


-- Add match
INSERT INTO matches (match_id, team1_id, team2_id, venue_id, result) 
VALUES (201, 1, 2, 101, 'India won by 45 runs');


-- Add venue
INSERT INTO venues (venue_name, city, country, capacity) 
VALUES ('Wankhede Stadium', 'Mumbai', 'India', 33000);

-- Add team
INSERT INTO teams (team_name, country) 
VALUES ('India', 'India');

-- Add match
INSERT INTO matches (team1_id, team2_id, venue_id, result) 
VALUES (1, 2, 1, 'India won by 45 runs');


SELECT 
    t.team_name,
    t.country AS team_country,
    SUM(CASE WHEN t.country = v.country THEN 1 ELSE 0 END) AS home_wins,
    SUM(CASE WHEN t.country != v.country THEN 1 ELSE 0 END) AS away_wins
FROM matches m
JOIN teams t ON m.winner_team_id = t.team_id
JOIN venues v ON m.venue_id = v.venue_id
GROUP BY t.team_id, t.team_name, t.country
ORDER BY home_wins DESC, away_wins DESC
LIMIT 1000;


DESCRIBE teams;

SELECT 
    t.team_name,
    CASE 
        WHEN t.country = m.venue_country THEN 'Home'
        ELSE 'Away'
    END AS match_location,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN m.result = 'Win' THEN 1 ELSE 0 END) AS total_wins
FROM matches m
JOIN teams t ON m.team_id = t.team_id
GROUP BY t.team_name, match_location
ORDER BY t.team_name, match_location;


DESCRIBE matches;

-- 12 --
SELECT 
    t.team_name,
    CASE 
        WHEN t.country = v.country THEN 'Home'
        ELSE 'Away'
    END AS match_location,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN m.winner_team_id = t.team_id THEN 1 ELSE 0 END) AS total_wins
FROM matches m
JOIN teams t ON m.team1_id = t.team_id OR m.team2_id = t.team_id
JOIN venues v ON m.venue_id = v.venue_id
GROUP BY t.team_name, match_location
ORDER BY t.team_name, match_location;



 SELECT 
    p1.player_name AS batsman_1,
    p2.player_name AS batsman_2,
    b1.innings_id,
    (b1.runs_scored + b2.runs_scored) AS partnership_runs
FROM batting_stats b1
JOIN batting_stats b2 
    ON b1.innings_id = b2.innings_id 
    AND b1.batting_position + 1 = b2.batting_position
JOIN players p1 ON b1.player_id = p1.player_id
JOIN players p2 ON b2.player_id = p2.player_id
WHERE (b1.runs_scored + b2.runs_scored) >= 100
ORDER BY partnership_runs DESC;


DESCRIBE batting_stats;


SELECT 
    p1.player_name AS batsman_1,
    p2.player_name AS batsman_2,
    bs1.match_id,
    bs1.team_id,
    (bs1.runs + bs2.runs) AS partnership_runs
FROM batting_stats bs1
JOIN batting_stats bs2 
    ON bs1.match_id = bs2.match_id
    AND bs1.team_id = bs2.team_id
    AND bs1.batting_position = bs2.batting_position - 1
JOIN players p1 ON bs1.player_id = p1.player_id
JOIN players p2 ON bs2.player_id = p2.player_id
WHERE (bs1.runs + bs2.runs) >= 100
ORDER BY bs1.match_id, partnership_runs DESC;


ALTER TABLE batting_stats
ADD COLUMN batting_position INT;


SELECT 
    p1.player_name AS batsman_1,
    p2.player_name AS batsman_2,
    bs1.match_id,
    (bs1.runs + bs2.runs) AS partnership_runs
FROM batting_stats bs1
JOIN batting_stats bs2 
    ON bs1.match_id = bs2.match_id
    AND bs1.batting_position = bs2.batting_position - 1
JOIN players p1 ON bs1.player_id = p1.player_id
JOIN players p2 ON bs2.player_id = p2.player_id
WHERE (bs1.runs + bs2.runs) >= 100
ORDER BY bs1.match_id, partnership_runs DESC;


SELECT 
    p1.player_name AS batsman_1,
    p2.player_name AS batsman_2,
    bs1.match_id,
    bs1.format,
    (bs1.runs + bs2.runs) AS partnership_runs
FROM batting_stats bs1
JOIN batting_stats bs2 
    ON bs1.match_id = bs2.match_id
    AND bs1.batting_position = bs2.batting_position - 1
JOIN players p1 ON bs1.player_id = p1.player_id
JOIN players p2 ON bs2.player_id = p2.player_id
WHERE (bs1.runs + bs2.runs) >= 100
ORDER BY bs1.match_id, partnership_runs DESC;


SELECT
    p1.player_name AS batsman_1,
    p2.player_name AS batsman_2,
    bs1.match_id,
    bs1.batting_position AS position_1,
    bs2.batting_position AS position_2,
    (bs1.runs + bs2.runs) AS partnership_runs
FROM batting_stats bs1
JOIN batting_stats bs2
    ON bs1.match_id = bs2.match_id
    AND bs1.batting_position = bs2.batting_position - 1
JOIN players p1 ON bs1.player_id = p1.player_id
JOIN players p2 ON bs2.player_id = p2.player_id
WHERE (bs1.runs + bs2.runs) >= 100
ORDER BY bs1.match_id, partnership_runs DESC;



SELECT
  p1.player_name AS batsman_1,
  p2.player_name AS batsman_2,
  bs1.match_id,
  (bs1.runs + bs2.runs) AS partnership_runs
FROM batting_stats bs1
JOIN batting_stats bs2
  ON bs1.match_id = bs2.match_id
  AND bs1.batting_position = bs2.batting_position - 1
JOIN players p1 ON bs1.player_id = p1.player_id
JOIN players p2 ON bs2.player_id = p2.player_id
WHERE (bs1.runs + bs2.runs) >= 100;




SELECT
  p1.player_name AS batsman_1,
  p2.player_name AS batsman_2,
  bs1.match_id,
  bs1.batting_position AS position_1,
  bs2.batting_position AS position_2,
  (bs1.runs + bs2.runs) AS partnership_runs
FROM batting_stats bs1
JOIN batting_stats bs2
  ON bs1.match_id = bs2.match_id
  AND bs1.batting_position = bs2.batting_position - 1
JOIN players p1 ON bs1.player_id = p1.player_id
JOIN players p2 ON bs2.player_id = p2.player_id;

INSERT INTO players (player_id, player_name)
VALUES (103, 'KL Rahul');

INSERT INTO batting_stats (match_id, player_id, runs, batting_position)
VALUES (1, 103, 70, 5);

-- 13--
SELECT
  p1.player_name AS batsman_1,
  p2.player_name AS batsman_2,
  bs1.match_id,
  bs1.batting_position AS position_1,
  bs2.batting_position AS position_2,
  (bs1.runs + bs2.runs) AS partnership_runs
FROM batting_stats bs1
JOIN batting_stats bs2
  ON bs1.match_id = bs2.match_id
  AND bs1.batting_position = bs2.batting_position - 1
JOIN players p1 ON bs1.player_id = p1.player_id
JOIN players p2 ON bs2.player_id = p2.player_id;


 SELECT 
    p.player_name,
    m.venue,
    COUNT(DISTINCT bs.match_id) AS matches_played,
    SUM(bs.wickets) AS total_wickets,
    ROUND(SUM(bs.runs_conceded) / SUM(bs.overs), 2) AS avg_economy_rate
FROM bowling_stats bs
JOIN players p ON bs.player_id = p.player_id
JOIN matches m ON bs.match_id = m.match_id
WHERE bs.overs >= 4
GROUP BY bs.player_id, m.venue
HAVING COUNT(DISTINCT bs.match_id) >= 3
ORDER BY m.venue, avg_economy_rate ASC;

DESCRIBE matches;


-- 14--
SELECT 
    p.player_name,
    v.venue_name,
    COUNT(DISTINCT bs.match_id) AS matches_played,
    SUM(bs.wickets) AS total_wickets,
    ROUND(SUM(bs.runs_conceded) / SUM(bs.overs), 2) AS avg_economy_rate
FROM bowling_stats bs
JOIN players p ON bs.player_id = p.player_id
JOIN matches m ON bs.match_id = m.match_id
JOIN venues v ON m.venue_id = v.venue_id
WHERE bs.overs >= 4
GROUP BY bs.player_id, v.venue_name
HAVING COUNT(DISTINCT bs.match_id) >= 3
ORDER BY v.venue_name, avg_economy_rate ASC;


 
-- 15-- 
WITH close_matches AS (
  SELECT match_id, winner_team_id
  FROM matches
  WHERE 
    (result LIKE '%run%' AND CAST(SUBSTRING_INDEX(result, ' ', -2) AS UNSIGNED) < 50)
    OR
    (result LIKE '%wicket%' AND CAST(SUBSTRING_INDEX(result, ' ', -2) AS UNSIGNED) < 5)
)

SELECT 
  p.player_name,
  COUNT(DISTINCT bs.match_id) AS close_matches_played,
  ROUND(AVG(bs.runs), 2) AS avg_runs_in_close_matches,
  SUM(CASE WHEN p.team_id = cm.winner_team_id THEN 1 ELSE 0 END) AS close_match_wins
FROM batting_stats bs
JOIN close_matches cm ON bs.match_id = cm.match_id
JOIN players p ON bs.player_id = p.player_id
GROUP BY bs.player_id
ORDER BY avg_runs_in_close_matches DESC
LIMIT 1000;



-- 16--
SELECT 
  p.player_name,
  YEAR(m.match_date) AS year,
  COUNT(DISTINCT bs.match_id) AS matches_played,
  ROUND(AVG(bs.runs), 2) AS avg_runs_per_match,
  ROUND(AVG((bs.runs / bs.balls) * 100), 2) AS avg_strike_rate
FROM batting_stats bs
JOIN matches m ON bs.match_id = m.match_id
JOIN players p ON bs.player_id = p.player_id
WHERE m.match_date >= '2020-01-01'
  AND bs.balls > 0  -- avoid divide-by-zero
GROUP BY bs.player_id, YEAR(m.match_date)
HAVING COUNT(DISTINCT bs.match_id) >= 5
ORDER BY year, avg_runs_per_match DESC;







ALTER TABLE matches ADD COLUMN toss_decision VARCHAR(10); -- 'bat' or 'bowl'

ALTER TABLE matches ADD COLUMN toss_winner_team_id INT;

CREATE TABLE toss_info (
  match_id INT PRIMARY KEY,
  toss_winner_team_id INT,
  toss_decision VARCHAR(10)
);


-- 17--
SELECT 
  toss_decision,
  COUNT(*) AS toss_winner_matches,
  SUM(CASE WHEN toss_winner_team_id = winner_team_id THEN 1 ELSE 0 END) AS toss_winner_wins,
  ROUND(
    (SUM(CASE WHEN toss_winner_team_id = winner_team_id THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
    2
  ) AS win_percentage
FROM matches
WHERE toss_decision IN ('bat', 'bowl')
GROUP BY toss_decision
ORDER BY win_percentage DESC;


 
 ALTER TABLE matches ADD COLUMN format VARCHAR(10);


-- 18--
SELECT 
  p.player_name,
  COUNT(DISTINCT bs.match_id) AS matches_played,
  SUM(bs.wickets) AS total_wickets,
  ROUND(SUM(bs.runs_conceded) / SUM(bs.overs), 2) AS economy_rate
FROM bowling_stats bs
JOIN matches m ON bs.match_id = m.match_id
JOIN players p ON bs.player_id = p.player_id
WHERE m.format IN ('ODI', 'T20')
GROUP BY bs.player_id
HAVING 
  COUNT(DISTINCT bs.match_id) >= 10
  AND (SUM(bs.overs) / COUNT(DISTINCT bs.match_id)) >= 2
ORDER BY economy_rate ASC
LIMIT 20;


-- 19--
SELECT 
  p.player_name,
  COUNT(*) AS innings_played,
  ROUND(AVG(bs.runs), 2) AS avg_runs,
  ROUND(STDDEV(bs.runs), 2) AS run_stddev
FROM batting_stats bs
JOIN matches m ON bs.match_id = m.match_id
JOIN players p ON bs.player_id = p.player_id
WHERE 
  m.match_date >= '2022-01-01'
  AND bs.balls >= 10
GROUP BY bs.player_id
HAVING COUNT(*) >= 1
ORDER BY run_stddev ASC, avg_runs DESC
LIMIT 20;

-- 20--
WITH format_stats AS (
  SELECT 
    bs.player_id,
    p.player_name,
    m.format,
    COUNT(DISTINCT bs.match_id) AS matches_played,
    ROUND(SUM(bs.runs) / COUNT(bs.match_id), 2) AS batting_average
  FROM batting_stats bs
  JOIN matches m ON bs.match_id = m.match_id
  JOIN players p ON bs.player_id = p.player_id
  GROUP BY bs.player_id, m.format
),
total_matches AS (
  SELECT player_id, SUM(matches_played) AS total_played
  FROM format_stats
  GROUP BY player_id
  HAVING SUM(matches_played) >= 20
)

SELECT 
  fs.player_name,
  fs.format,
  fs.matches_played,
  fs.batting_average
FROM format_stats fs
JOIN total_matches tm ON fs.player_id = tm.player_id
ORDER BY fs.player_name, fs.format;





















