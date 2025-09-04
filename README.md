# 🏏 Cricbuzz LiveStats: Real-Time Cricket Insights & SQL-Based Analytics  

## 📌 Overview  
**Cricbuzz LiveStats** is a Streamlit-based web app that delivers **real-time cricket match insights** powered by the **Cricbuzz RapidAPI**.  
It integrates **live match data**, **SQL-based analytics**, and **player stats tracking** into one seamless dashboard — perfect for fans, analysts, fantasy cricket users, and students.  

## 🚀 Features  
- **Live Match Dashboard**:  
  - Real-time scores, match info, and scorecards.  
  - Match selection with stable dropdown & session state handling.  
  - Optional auto-refresh for live updates.  

- **SQL Analytics**:  
  - 25+ pre-built SQL queries (Beginner → Advanced).  
  - Covers player stats, match insights, team performance.  
  - Visualized with charts & tables.  

- **CRUD Operations**:  
  - Manage players, matches, innings, and stats.  
  - Full Create/Read/Update/Delete support with validation.  

- **Top Player Stats**:  
  - Find top run scorers, wicket-takers, and form-based leaders.  

- **Database Integration**:  
  - Supports **MySQL/Postgres/SQLite**.  
  - Normalized schema with tables for `matches`, `players`, `innings`, `batting`, `bowling`, `venues`, `series`.  
  - Sample seed data included.  

---

## 🛠️ Tech Stack  
- **Frontend/UI**: [Streamlit](https://streamlit.io/)  
- **Backend/API**: [Cricbuzz RapidAPI](https://rapidapi.com/)  
- **Database**: MySQL / PostgreSQL / SQLite  
- **Languages**: Python, SQL  
- **Libraries**: `pandas`, `requests`, `sqlalchemy`, `plotly`, `streamlit`  

---

## 📂 Project Structure  
```
📦 Cricbuzz-LiveStats
├── main.py                  # Entry point (Streamlit multi-page app)
├── pages/                   # Streamlit pages
│   ├── 1_Live_Match.py
│   ├── 2_SQL_Analytics.py
│   ├── 3_Top_Player_Stats.py
│   ├── 4_CRUD_Operations.py
├── utils/
│   ├── api_helpers.py        # API fetch functions
│   ├── db_connection.py      # DB connection setup
│   ├── queries.py            # SQL query collection
├── data/
│   ├── db_schema.sql         # Database schema
│   ├── seed_data.sql         # Sample data
├── requirements.txt
├── README.md
```

---

## ⚡ Setup & Installation  

### 1️⃣ Clone the repo  
```bash
git clone https://github.com/monikha-19/Cricbuzz-LiveStats.git  ##
cd Cricbuzz-LiveStats
```

### 2️⃣ Install dependencies  
```bash
pip install -r requirements.txt
```

### 3️⃣ Configure API Keys & DB  
Create a `.streamlit/secrets.toml` file:  
```toml
[RAPIDAPI]
X-RapidAPI-Key = "87bba7f153msh356cdb14eb98eacp1d0e4bjsn5f6432aecad2"                                 ##
X-RapidAPI-Host = "cricbuzz-cricket.p.rapidapi.com"

[DB]
host = "localhost"
user = "root"
password = "monikha_19"
database = "cricbuzz_db"
```

### 4️⃣ Setup Database  
```bash
mysql -u root -p cricbuzz < data/db_schema.sql
mysql -u root -p cricbuzz < data/seed_data.sql
```

### 5️⃣ Run the app  
```bash
streamlit run main.py
```

---

## 📊 Example SQL Queries  
- **Beginner**: Top 5 run scorers.  
- **Intermediate**: Highest partnership per match.  
- **Advanced**: Player consistency using window functions.    

---

## 🌟 Use Cases  
- 📡 **Media**: Live coverage dashboards.  
- 🎲 **Fantasy Cricket**: Player performance insights.  
- 📈 **Analytics Firms**: Historical + real-time data exploration.  
- 🎓 **Education**: SQL & Data Engineering practice project.  

---

## 🤝 Contribution  
Pull requests are welcome. For major changes, please open an issue first.  

---
 

