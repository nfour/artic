A = require './app'
routers = require './handlers/routers'

module.exports = [
	# Artic API
	[ '*',		'*',								routers.session ]
	[ '*',		'/artic/api/:controller(*)',		routers.api ]
	
	# Admin area
	[ 'GET',	'/artic/:controller(*)?',			routers.admin ]
	
	# Public
	#[ 'GET',	'/page/:title',	routers.paging ]
	#[ 'GET',	'/article/:title',	routers.article ]
	
	[ '*',		'/*',								routers['404'] ]

]