
path = require 'path'

module.exports =
	template: 'default'
	
	routes: []
	
	lance:
		server:
			static: './static'
		
		templater:
			autoConstruct: false
			templater:
				ext: '.ect'
				options:
					cache	: true
					watch	: true
					open	: '<<'
					close	: '>>'
		logging:
			debug:
				render: true
				files: true
				errors: true
			
	database:
		resetSchema	: true
		resetStores	: true
		resetDelay	: 30
		
		client		: 'sqlite'
		debug		: false
		connection	:
			#host	: 'localhost'
			charset	: 'utf8'
			filename: 'artic.sqlite'

	dataSubstitution: true

	cache:
		enabled: true
		session:
			prefix: 'u' # prefix + user.id such as "u789"
			timeout: 1000 * 60 * 5
			enabled: true
	
	crypto:
		algorithm: 'md5'

	adminTemplater:
		findIn: './templates/admin'
		
		bundles:
			'app.js'	: './js/app.coffee'
			'style.css'	: './css/style.styl'

		templater:
			ext: '.ect'
			options:
				cache	: true
				watch	: true
				open	: '<<'
				close	: '>>'



