# cricbuzz_dashboard.py

import os
import requests
import pandas as pd
import mysql.connector
import streamlit as st
from datetime import datetime

import time
import io
import collections

# ---------------- App Setup ----------------
st.set_page_config(page_title="Cricbuzz LiveStats", page_icon="🏏", layout="wide")

# ---------------- Config / Secrets ----------------
DEFAULT_RAPIDAPI_KEY = "87bba7f153msh356cdb14eb98eacp1d0e4bjsn5f6432aecad2"  # ✅ new key

def get_rapidapi_key():
    try:
        return st.secrets.get("RAPIDAPI_KEY", DEFAULT_RAPIDAPI_KEY)
    except Exception:
        return os.getenv("RAPIDAPI_KEY", DEFAULT_RAPIDAPI_KEY)

def rapidapi_headers():
    return {
        "x-rapidapi-key": get_rapidapi_key(),
        "x-rapidapi-host": "cricbuzz-cricket.p.rapidapi.com",
    }

# ============================================================
# Cricbuzz API Wrappers
# ============================================================
def fetch_live_matches():
    url = "https://cricbuzz-cricket.p.rapidapi.com/matches/v1/live"
    resp = requests.get(url, headers=rapidapi_headers())
    if resp.status_code != 200:
        return []
    data = resp.json()
    matches = []
    for series in data.get("seriesMatches", []):
        for match in series.get("seriesAdWrapper", {}).get("matches", []):
            info = match.get("matchInfo", {})
            if not info:
                continue
            matches.append({
                "match_id": info.get("matchId"),
                "team1": info.get("team1", {}).get("teamName"),
                "team2": info.get("team2", {}).get("teamName"),
                "venue": info.get("venueInfo", {}).get("ground"),
                "status": info.get("status"),
            })
    return matches


def get_full_scorecard(match_id):
    url = f"https://cricbuzz-cricket.p.rapidapi.com/mcenter/v1/{match_id}/scorecard"
    resp = requests.get(url, headers=rapidapi_headers())
    if resp.status_code != 200:
        return None
    data = resp.json()
    innings = []
    for inn in data.get("scorecard", []):
        innings.append({
            "inning_name": inn.get("inningName"),
            "batting": list(inn.get("batTeamDetails", {}).get("batsmenData", {}).values()),
            "bowling": list(inn.get("bowlTeamDetails", {}).get("bowlersData", {}).values()),
            "fow": list(inn.get("wicketsData", {}).values()),
        })
    return {"innings": innings}


def search_players(name):
    url = f"https://cricbuzz-cricket.p.rapidapi.com/stats/v1/player/search?plrN={name}"
    resp = requests.get(url, headers=rapidapi_headers())
    if resp.status_code == 200:
        return resp.json().get("player", [])
    return []

def get_player_profile(player_id):
    url = f"https://cricbuzz-cricket.p.rapidapi.com/stats/v1/player/{player_id}"
    resp = requests.get(url, headers=rapidapi_headers())
    if resp.status_code == 200:
        return resp.json()
    return {}

# ============================================================
# DB Connection
# ============================================================
def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="monikha_19",
        database="cricbuzz_db",
        autocommit=True,
    )

def run_query(sql, params=None, dict_rows=True):
    conn = get_connection()
    cursor = conn.cursor(dictionary=dict_rows)
    cursor.execute(sql, params or ())
    if cursor.with_rows:
        rows = cursor.fetchall()
        if rows:
            # Always return DataFrame
            return pd.DataFrame(rows)
        return pd.DataFrame()   # empty DataFrame if no result
    conn.commit()
    return None


# ============================================================
# Sidebar
# ============================================================
st.sidebar.title("Cricbuzz LiveStats")
page = st.sidebar.radio(
    "Go to",
    ["Home", "Live Match", "Top Player Stats", "SQL Queries & Analytics", "CRUD Operations"]
)

# ============================================================
# 1) HOME
# ============================================================
if page == "Home":
    st.title("🏏 Cricbuzz LiveStats Dashboard")
    st.markdown("""
**Features**
- ⚡ Live Match updates
- 🏆 Top Player Stats
- 📊 SQL-based Analytics
- 🛠️ CRUD operations
    """)

# =========================================================================================
#2).=================================LIVE MATCHES============================================
elif page == "Live Match":
    st.title("🏏 Cricbuzz Live Match Dashboard")

    live_url = "https://cricbuzz-cricket.p.rapidapi.com/matches/v1/live"
    recent_url = "https://cricbuzz-cricket.p.rapidapi.com/matches/v1/recent"

    def fetch_matches(url):
        try:
            r = requests.get(url, headers=rapidapi_headers(), timeout=10)
            return r.json() if r.status_code == 200 else {}
        except Exception as e:
            st.error(f"⚠️ API request failed: {e}")
            return {}

    live_data = fetch_matches(live_url)
    recent_data = fetch_matches(recent_url)

    rows = []
    def parse(data, tag):
        for tm in data.get("typeMatches", []):
            for sm in tm.get("seriesMatches", []):
                wrapper = sm.get("seriesAdWrapper")
                if not wrapper:
                    continue
                series_name = wrapper.get("seriesName", "Unknown Series")
                for match in wrapper.get("matches", []):
                    info = match.get("matchInfo")
                    if not info:
                        continue
                    mid = info.get("matchId")
                    if mid is None:
                        continue
                    uid = f"{tag}-{str(mid)}"
                    label = (
                        f"[{tag}] {info.get('team1', {}).get('teamName')} vs "
                        f"{info.get('team2', {}).get('teamName')} • "
                        f"{info.get('matchDesc')} • {info.get('status')}"
                    )
                    rows.append({
                        "uid": uid,
                        "label": label,
                        "series": series_name,
                        "info": info,
                        "score": match.get("matchScore", {})
                    })

    parse(live_data, "LIVE")
    parse(recent_data, "RECENT")

    if not rows:
        st.info("No matches available right now.")
        st.stop()

    # Build option list
    option_ids = [r["uid"] for r in rows]
    option_labels = {r["uid"]: r["label"] for r in rows}
    id_to_row = {r["uid"]: r for r in rows}

    ss_key = "live_match_selected_id"
    selectbox_key = "live_match_selectbox_unique"

    if ss_key not in st.session_state:
        st.session_state[ss_key] = option_ids[0]

    if st.session_state[ss_key] not in option_ids:
        st.session_state[ss_key] = option_ids[0]

    def _on_change_select():
        st.session_state[ss_key] = st.session_state.get(selectbox_key)

    initial_index = option_ids.index(st.session_state[ss_key])

    selected_uid = st.selectbox(
        "🎯 Select a Match",
        options=option_ids,
        index=initial_index,
        format_func=lambda uid: option_labels.get(uid, uid),
        key=selectbox_key,
        on_change=_on_change_select
    )

    chosen_uid = st.session_state.get(ss_key, selected_uid)
    chosen = id_to_row.get(chosen_uid)
    if not chosen:
        st.error("Selected match not found.")
        st.stop()

    info = chosen["info"]
    score = chosen.get("score", {})

    st.subheader(f"🏆 {chosen['series']}")
    st.write(f"📌 {info.get('matchDesc')} | 📊 {info.get('status')}")

    def safe_inngs(s, key="inngs1"):
        if not s:
            return {}
        return (s.get(key) or {}) if isinstance(s, dict) else {}

    t1s = safe_inngs(score.get("team1Score", {}))
    t2s = safe_inngs(score.get("team2Score", {}))

    st.write(f"**{info.get('team1', {}).get('teamName')}** {t1s.get('runs','-')}/{t1s.get('wickets','-')} ({t1s.get('overs','-')} ov)")
    st.write(f"**{info.get('team2', {}).get('teamName')}** {t2s.get('runs','-')}/{t2s.get('wickets','-')} ({t2s.get('overs','-')} ov)")

    if st.button("📜 View Full Scorecard"):
        sc = get_full_scorecard(info.get("matchId"))
        if sc and sc.get("innings"):
            for inn in sc.get("innings", []):
                st.markdown(f"### 🏏 {inn.get('inning_name', 'Innings')}")
                if inn.get("batting"):
                    st.dataframe(pd.DataFrame(inn.get("batting")))
                if inn.get("bowling"):
                    st.dataframe(pd.DataFrame(inn.get("bowling")))



# ============================================================
# 3) TOP PLAYER STATS
# ============================================================
elif page == "Top Player Stats":
    st.title("🏆 Top Player Stats")
    search_query = st.text_input("Enter player name")
    if search_query:
        players = search_players(search_query)
        if players:
            options = {p.get("name", "Unknown"): p.get("id") for p in players}
            selected_player = st.selectbox("Select a player", list(options.keys()))
            if st.button("Show Details"):
                player_id = options[selected_player]
                profile = get_player_profile(player_id)
                st.markdown(f"### {profile.get('name')} ({profile.get('country')})")
                st.write(f"**Role:** {profile.get('role')}")
                st.write(f"**Batting Style:** {profile.get('battingStyle')}")
                st.write(f"**Bowling Style:** {profile.get('bowlingStyle')}")

                if profile.get("battingStats"):
                    st.write("📊 Batting Stats")
                    st.dataframe(pd.DataFrame.from_dict(profile["battingStats"], orient="index"))

                if profile.get("bowlingStats"):
                    st.write("🎯 Bowling Stats")
                    st.dataframe(pd.DataFrame.from_dict(profile["bowlingStats"], orient="index"))

                st.markdown(f"[View Full Profile](https://www.cricbuzz.com/profiles/{player_id})", unsafe_allow_html=True)


# ============================================================
# 4) SQL QUERIES & ANALYTICS 
# ============================================================
elif page == "SQL Queries & Analytics":
    st.title("🗃️ SQL Queries & Analytics")
    st.markdown("Select one of the 25 project questions below. The SQL string used is shown so you can tweak it to match your schema.")

    # Dictionary mapping each question label -> SQL (pre-populated based on your problem statements)
    queries = {
        "Q1: Players who represent India": """
            SELECT player_name, role
            FROM players
            WHERE team_id = (
            SELECT team_id FROM teams WHERE country = 'India'
            )
            LIMIT 1000;
            """,
        "Q2: Matches in last 30 days": """
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
        """,
        "Q3: Top 10 run scorers in ODI": """
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
        """,
        "Q4: Venues with capacity > 50k": """
             SELECT venue_name, city, country, capacity
FROM venues
WHERE capacity > 50000
ORDER BY capacity DESC;
        """,
        "Q5: Matches each team has won": """
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

        """,
        "Q6: Count players by role": """
             SELECT 
    role,
    COUNT(*) AS player_count
FROM players
GROUP BY role
ORDER BY player_count DESC;
        """,
        "Q7: Highest individual batting score by format": """
             SELECT 
    format,
    MAX(runs) AS highest_score
FROM batting_stats
GROUP BY format
ORDER BY highest_score DESC;
        """,
        "Q8: Series started in 2024": """
             SELECT 
    name AS series_name,
    host_country,
    match_type,
    year,
    total_matches
FROM tournaments
WHERE year = 2024
ORDER BY name;
        """,
        "Q9: All-rounders 1000+ runs & 50+ wickets": """
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
        """,
        "Q10: Last 20 completed matches": """
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
        """,
        "Q11: Player performance across formats (played >=2 formats)": """
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
        """,
        "Q12: Team home vs away performance": """
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
        """,
        "Q13: Partnerships 100+ by consecutive batsmen": """
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
        """,
        "Q14: Bowling performance at venues (>=3 matches)": """
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
        """,
        "Q15: Players performing in close matches": """
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

        """,
        "Q16: Player yearly avg runs & strike rate since 2020 (min 5 matches/year)": """
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
        """,
        "Q17: Advantage of winning toss by toss decision": """
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
        """,
        "Q18: Most economical bowlers in limited overs (>=10 matches)": """
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

        """,
        "Q19: Consistent batsmen (avg & stddev since 2022, faced >=10 balls per innings)": """
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

        """,
        "Q20: Matches & batting average by format (players with >=20 total matches)": """
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

        """,
        "Q21: Comprehensive performance ranking by format (sample score)": """
            /* This is an example ranking. Adjust weightings to match your available columns */
            SELECT p.player_name, m.format,
                   ( (COALESCE(b.total_runs,0) * 0.01) + (COALESCE(b.avg,0) * 0.5) + (COALESCE(b.sr,0) * 0.3)
                   + (COALESCE(bo.total_wickets,0) * 2) + ((50 - COALESCE(bo.avg,50)) * 0.5) + ((6 - COALESCE(bo.econ,6)) * 2)
                   + (COALESCE(f.catches,0) * 1) ) AS performance_score
            FROM players p
            LEFT JOIN ( -- batting aggregates
               SELECT player_id, SUM(runs) AS total_runs, AVG(batting_average) AS avg, AVG(strike_rate) AS sr
               FROM batting_stats GROUP BY player_id
            ) b ON p.player_id = b.player_id
            LEFT JOIN ( -- bowling aggregates
               SELECT player_id, SUM(wickets) AS total_wickets, AVG(bowling_average) AS avg, AVG(economy) AS econ
               FROM bowling_stats GROUP BY player_id
            ) bo ON p.player_id = bo.player_id
            LEFT JOIN ( -- fielding aggregates (example)
               SELECT f.player_id, SUM(f.catches) as catches FROM fielding_stats f GROUP BY f.player_id
            ) f ON p.player_id = f.player_id
            LEFT JOIN matches m ON 1=1
            LIMIT 100;
        """,
        "Q22: Head-to-head match prediction (pairs with >=5 matches in last 3 years)": """
            -- Pairwise head-to-head (team ids stored ascending for unique pair)
            SELECT t1.team_name AS team_a, t2.team_name AS team_b,
                   COUNT(*) AS total_matches,
                   SUM(CASE WHEN m.winner = t1.team_name THEN 1 ELSE 0 END) AS wins_for_a,
                   SUM(CASE WHEN m.winner = t2.team_name THEN 1 ELSE 0 END) AS wins_for_b,
                   ROUND(AVG(m.victory_margin),2) AS avg_margin
            FROM matches m
            JOIN teams t1 ON m.team1_id = t1.team_id
            JOIN teams t2 ON m.team2_id = t2.team_id
            WHERE m.match_date >= DATE_SUB(CURDATE(), INTERVAL 3 YEAR)
            GROUP BY m.team1_id, m.team2_id
            HAVING COUNT(*) >= 5;
        """,
        "Q23: Recent form (last 10 performances) & categorization": """
            /* This query returns last 10 scores per player; further logic to compute categories should be done in Python */
            SELECT b.player_id, p.player_name, m.match_date, b.runs, b.strike_rate
            FROM batting_stats b
            JOIN matches m ON b.match_id = m.match_id
            JOIN players p ON b.player_id = p.player_id
            ORDER BY b.player_id, m.match_date DESC;
        """,
        "Q24: Successful batting partnerships (>=5 partnerships)": """
            SELECT p1.player_name AS player1, p2.player_name AS player2,
                   AVG(bp.runs) AS avg_partnership, SUM(CASE WHEN bp.runs >= 50 THEN 1 ELSE 0 END) AS fifty_plus_count,
                   MAX(bp.runs) AS highest_partnership,
                   COUNT(*) AS partnerships_count,
                   ROUND( SUM(CASE WHEN bp.runs >= 50 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2 ) AS success_rate_pct
            FROM batting_partnerships bp
            JOIN players p1 ON bp.player1_id = p1.player_id
            JOIN players p2 ON bp.player2_id = p2.player_id
            WHERE ABS(bp.position1 - bp.position2) = 1
            GROUP BY p1.player_name, p2.player_name
            HAVING COUNT(*) >= 5
            ORDER BY avg_partnership DESC;
        """,
        "Q25: Time-series player performance (quarterly)": """
            /* This query returns per-match data; time-series aggregation should be done in Python for flexibility */
            SELECT p.player_name, m.match_date, b.runs, b.strike_rate
            FROM batting_stats b
            JOIN players p ON b.player_id = p.player_id
            JOIN matches m ON b.match_id = m.match_id
            ORDER BY p.player_name, m.match_date;
        """
    }

    # Select question
    question_label = st.selectbox("Choose a question (1 - 25)", list(queries.keys()))
    sql_text = queries[question_label]

    st.markdown("**SQL used (editable)**")
    sql_editor = st.text_area("SQL", value=sql_text, height=240)

    col1, col2 = st.columns([1, 3])
    with col1:
        run = st.button("Run Query")
        download = st.button("Download CSV of last result")
    with col2:
        st.markdown("**Notes**")
        st.write("If a query returns no results, check your DB schema and table / column names. Some advanced queries require the presence of specific helper tables (e.g., `fielding_stats`, `batting_partnerships`).")

    # Execute
    if run:
        start = time.time()
        df = run_query(sql_editor)
        elapsed = time.time() - start
        st.success(f"Query executed in {elapsed:.2f}s — {len(df)} rows returned")
        st.dataframe(df)
        # allow CSV download
        csv_buffer = io.StringIO()
        df.to_csv(csv_buffer, index=False)
        csv_bytes = csv_buffer.getvalue().encode("utf-8")
        st.download_button("Download result as CSV", csv_bytes, file_name=f"query_result_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")


# ============================================================
# 5) CRUD OPERATIONS (players table)
# ============================================================
elif page == "CRUD Operations":
    st.title("📝 CRUD Operations (Players)")
    action = st.selectbox("Select Action", ["Create Player", "Read Players", "Update Player", "Delete Player"])

    if action == "Create Player":
        name = st.text_input("Player Name")
        role = st.selectbox("Role", ["Batsman", "Bowler", "All-rounder", "Wicket-keeper"])
        team_id = st.number_input("Team ID", min_value=1, step=1)
        if st.button("Add Player"):
            try:
                run_query(
                    "INSERT INTO players (player_name, role, team_id) VALUES (%s, %s, %s)",
                    (name, role, team_id),
                    dict_rows=False,
                )
                st.success("✅ Player added.")
            except mysql.connector.Error as e:
                st.error(f"MySQL Error: {e}")

    elif action == "Read Players":
        try:
            rows = run_query("SELECT player_id, player_name, role, team_id FROM players ORDER BY player_id")
            st.dataframe(pd.DataFrame(rows) if rows else pd.DataFrame())
        except mysql.connector.Error as e:
            st.error(f"MySQL Error: {e}")

    elif action == "Update Player":
        pid = st.number_input("Player ID to Update", min_value=1, step=1)
        new_name = st.text_input("New Name")
        new_role = st.selectbox("New Role", ["(no change)", "Batsman", "Bowler", "All-rounder", "Wicket-keeper"])
        new_team = st.number_input("New Team ID (0 = no change)", min_value=0, step=1)

        if st.button("Update"):
            sets = []
            params = []
            if new_name:
                sets.append("player_name=%s")
                params.append(new_name)
            if new_role != "(no change)":
                sets.append("role=%s")
                params.append(new_role)
            if new_team != 0:
                sets.append("team_id=%s")
                params.append(int(new_team))

            if not sets:
                st.info("Nothing to update.")
            else:
                params.append(int(pid))
                sql = f"UPDATE players SET {', '.join(sets)} WHERE player_id=%s"
                try:
                    run_query(sql, tuple(params), dict_rows=False)
                    st.success("✅ Player updated.")
                except mysql.connector.Error as e:
                    st.error(f"MySQL Error: {e}")

    elif action == "Delete Player":
        pid = st.number_input("Player ID to Delete", min_value=1, step=1)
        if st.button("Delete"):
            try:
                run_query("DELETE FROM players WHERE player_id=%s", (int(pid),), dict_rows=False)
                st.success("🗑️ Player deleted.")
            except mysql.connector.Error as e:
                st.error(f"MySQL Error: {e}")

 