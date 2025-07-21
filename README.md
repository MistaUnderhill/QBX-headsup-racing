# QBX Street Race Script

## Features
- Multiplayer street racing
- Buy-in pot and payout system
- Leaderboard with win tracking
- Tax option for server cut
- Radial menu race start

## Setup

### 1. SQL Table
Run this in your database:

```sql
CREATE TABLE IF NOT EXISTS street_race_leaderboard (
    identifier VARCHAR(64) PRIMARY KEY,
    name VARCHAR(100),
    wins INT DEFAULT 0
);
,

2. Add to server.cfg:
ensure qb-street-race

3. Radial Menu:
Add this to your radial menu config:

{
    id = "start_street_race",
    title = "Start Street Race",
    icon = "flag-checkered",
    onSelect = function()
        TriggerEvent('qb-street-race:startRaceRadial')
    end
}

Usage
Go near others in vehicles and use the radial menu to start a race.

Players nearby in cars will automatically be included.

Winner receives pot after tax.

View top 10 with /raceleaderboard

Config
Located in config.lua.

Config.BuyInAmount = 5000
Config.MinDistance = 1000
Config.MaxDistance = 1500
Config.TaxPercent = 0.15
Config.JoinDistance = 50.0
