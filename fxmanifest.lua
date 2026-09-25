fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dj-backpacks'
author 'DieselJones21'
description 'ox_inventory duffle bags that persist across restarts without adding inner weight'
version '1.0.0'

dependencies {
    'ox_lib',
    'ox_inventory',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/bags.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

files {
    'locales/*.json',
    'web/images/*.png',
}
