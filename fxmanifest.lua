fx_version 'cerulean'
game 'gta5'

author 'Mistaunderhill'
description 'Multiplayer Street Race Script for QBX'
version '2.0.0'

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
