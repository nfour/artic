A = require '../app'

{ merge, clone, typeOf } = A.utils

module.exports = ->
	userRoutes = A.cfg.routes
	
	switch
		when userRoutes is false
			A.routes = A.cfg.lance.routes or []
		
		when typeOf.Array( userRoutes ) and userRoutes.length
			A.routes = userRoutes.concat A.routes
	
	A.router.on 'matched', (result) ->
		console.log 'matched'.green, result

	if A.routes.length
		A.lance.router.route route for route in A.routes

	return A.routes