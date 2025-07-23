# QBX Street Race Script

## Features
- Multiplayer street racing from current location to random GPS
- Buy-in pot and payout system
- Leaderboard with win tracking
- Tax option for server cut
- Radial menu race start
- two racer minimum to start

## Setup

### 1. SQL Table
Run this in your database:

```sql
CREATE TABLE IF NOT EXISTS `players` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(64) NOT NULL,
    `metadata` TEXT NOT NULL DEFAULT '{}',
    -- other columns like identifiers, cash, etc. as per your existing schema
    INDEX (`name`)
);
```

### 2. Add to server.cfg:
```
ensure qbx-street-racing
```

### 3. Radial Menu:
Add this to your radial menu config:
```
{
    id = "start_street_race",
    title = "Start Street Race",
    icon = "flag-checkered",
    onSelect = function()
        TriggerEvent('qbx-street-racing:startRaceRadial')
    end
}
```
### Usage
Go near others in vehicles and use the radial menu to start a race.

Players nearby in cars will automatically be included.

Winner receives pot after tax.

View top 10 with /raceleaderboard

### Config
Located in config.lua.
```
-- Distance (in meters) from race start to checkpoint
Config.RaceDistance = 1000.0

-- Radius to check for players in vehicles near the race starter
Config.JoinDistance = 50.0

-- Buy-in settings
Config.MinBuyIn = 500
Config.MaxBuyIn = 5000

-- Tax settings (set to 0 for no tax, or a value like 0.1 for 10%)
Config.RaceTax = 0.0

-- Countdown time in seconds before race start (locked players + countdown)
Config.CountdownTime = 3

```
