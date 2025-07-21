# QBX-headsup-racing
Street Race Script for QBX
Overview
This script enables multiplayer street races in FiveM using QBX framework with configurable buy-in, race distance, tax, and a leaderboard tracking wins.
Race start is triggered via a radial menu option.

Installation
Create database table

Run this SQL in your MySQL database:

sql
Copy
Edit
CREATE TABLE IF NOT EXISTS street_race_leaderboard (
    identifier VARCHAR(64) PRIMARY KEY,
    name VARCHAR(100),
    wins INT DEFAULT 0
);
Add resource files
Place the following files in your resource folder:

config.lua

fxmanifest.lua

server.lua

client.lua

Start resource
Add to your server config:

ini
Copy
Edit
ensure qb-street-race
Configuration (config.lua)
lua
Copy
Edit
Config = {}

Config.BuyInAmount = 5000      -- Entry fee per player (bank)
Config.MinDistance = 1000      -- Min race checkpoint distance (meters)
Config.MaxDistance = 1500      -- Max race checkpoint distance (meters)
Config.TaxPercent = 0.15       -- Tax percent from total pot (0 = no tax)
Config.JoinDistance = 50.0     -- Max distance to join race (meters)
Radial Menu Integration
Add this option to your radial menu config:

lua
Copy
Edit
{
    id = "start_street_race",
    title = "Start Street Race",
    icon = "flag-checkered",
    onSelect = function()
        TriggerEvent('qb-street-race:startRaceRadial')
        -- OR if radial menu supports exports:
        -- exports['qb-street-race']:StartRaceFromRadial()
    end
}
Commands
/raceleaderboard — Show top 10 racers and wins.

How it works
Players in vehicles within JoinDistance meters when the race is started are entered into the race if they can pay the buy-in.

First to reach the checkpoint wins the pot minus tax.

Wins are recorded in the leaderboard and can be viewed with /raceleaderboard.
