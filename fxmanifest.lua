fx_version 'cerulean'
game 'gta5'

author 'IQ Dev'
description 'Vehicle Control and Information System'
version '1.0.0'

ui_page 'html/index.html'

client_scripts {
    'client/main.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png'
} 

-- Export functions
exports {
    'toggleEngine',
    'toggleLock',
    'toggleHood',
    'toggleTrunk',
    'switchSeat'
} 