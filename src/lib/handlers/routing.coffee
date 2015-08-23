A = require '../app'
TransInterpolator = require 'trans-interpolator'

{ merge, clone, typeOf } = A.utils

module.exports = ->
	userRoutes = A.cfg.routes
	
	switch
		when userRoutes is false
			A.routes = A.cfg.lance.routes or []
		
		when typeOf.Array( userRoutes ) and userRoutes.length
			A.routes = userRoutes.concat A.routes

	if A.routes.length
		A.lance.router.route route for route in A.routes

	###
		Handles interpolation of template rendered variables.
		eg. "{{settings.title}}!" to "Artic!"
	###
	A.lance.on 'serve.template', (o) ->
		data		= o.template.data
		fullData	= merge.black data, A.locals
		
		interp = new TransInterpolator fullData
		
		# TODO: make this a configurable whitelist
		selections = [ 'settings', 'text' ]
		
		for key in selections when typeOf.Object data[key]
			obj = data[key] = clone data[key]
			for key, val of obj when typeOf.String val
				obj[key] = interp.interpolate val


	return A.routes