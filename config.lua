-- config.lua

Config = {}

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

-- Timeout for racer confirmations (in seconds)
Config.ConfirmationTimeout = 30

-- Maximum number of racers allowed per race
Config.MaxRacers = 10
