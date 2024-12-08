fx_version 'cerulean'
game 'gta5'

author 'Dijkslag'
description 'A Bank Truck Robbery Script'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}
server_script 'server/server.lua'
client_script 'client/client.lua'
dependencies {
    'qb-core',
    'qb-target'
}
