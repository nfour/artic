Artic = require '../../'

artic = Artic {
	root: __dirname
	database:
		resetDelay: -1
		
	routes: [
		[ "*", "/", 'home test', (o) ->
			o.serve { view: 'home' }
		]

	]
		
	lance:
		server:
			static	: './static'
			
		root	: __dirname

		
		templater:
			ext: '.etc'


}




artic.initialize().then ->
	#console.log artic.templater.cfg
	console.log '[[[[[[[[[[ARTIC INTIALIZED]]]]]]]]]]'


	artic.router.route [ "*", "*", 'home 404 test', (o) ->
		console.log '404 route manual'
		o.serve { view: 'home' }
	]
	