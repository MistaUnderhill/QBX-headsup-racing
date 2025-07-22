fx_version 'cerulean'
game 'gta5'

author 'Mistaunderhill'
description 'Multiplayer Street Race Script for QBX'
version '2.0.0'

-- Register with qbx-core metadata
resource_type 'gametype' { name = 'StreetRace' }
dependency 'qbx-core'

shared_script 'config.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

client_scripts {
    'client.lua',
}

dependencies {
    'oxmysql',
    'qbx-core'
}
