fx_version 'cerulean'
game 'gta5'

author 'chuj cie to'
description 'Tracker ala FutureRP i chuj'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'es_extended',
    'ox_target',
    'ox_lib'
}