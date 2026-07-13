fx_version 'cerulean'
game 'gta5'
lua54 'yes'
version '1.1.0'

ui_page 'web/dist/index.html'

shared_scripts {
	'@ox_lib/init.lua',
}

client_scripts {
	"client/*.lua",
}

files {
	'web/dist/index.html',
	'web/dist/**/*',
}
