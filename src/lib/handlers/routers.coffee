A		= require '../app'
Promise	= require 'bluebird'
path	= require 'path'

A.coroutiner module.exports = routers =
	session: (o) ->
		console.log 'route:session'.yellow
		o.session = new A.handlers.Session o
		
		yield return o.next()

	###
		Finds a controller in ./controllers/api/
	###
	api: (o) ->
		console.log 'route:api'.yellow
		try
			{ session } = o
			keys = o.path.controller.split '/'
			
			user = yield session.auth()
			
			if keys[0] isnt 'session'
				throw 'Invalid Session' if not user
			
			if not controller = new A.modules.ControllerFinder( A.controllers.api ).find keys
				throw 'Invalid API'

			yield controller o
		catch err
			return routers.error o, err

		yield return o.serve()

	###
		Renders a view at './views/' + route.name
	###
	view: (o) ->
		console.log 'route:view'.yellow
		{ route, template, session } = o

		template.view = route.name

		yield return o.serve()

	###
		Finds a controller in ./controllers
	###
	controller: (o) ->
		console.log 'route:controller'.yellow
		{ route, template, session } = o
		
		try
			keys = o.path.controller.split /[\/.]/g
			console.log 'controller', keys
			
			if not controller = new A.modules.ControllerFinder( A.controllers ).find keys
				throw 'Invalid API'
				
			yield controller o
		catch err
			return routers.error o, err
		
		yield return o.serve()

	###
		Handles bubbled up errors consistantly
	###
	error: (o, err) ->
		console.log 'route:error'.yellow
		if o.template.view
			o.template.view = 'pages/error'
			A.lance.emit 'error', err, "route #{ o.route.name }" # temporary debugging
		else
			# reset the json for security
			o.json = {}

			if err instanceof Error
				o.json.error = 'Internal Error'
			else
				o.json.error = err

		if err instanceof Error
			A.lance.emit 'error', err, "route #{ o.route.name }"

		yield return o.serve()

	404: (o) ->
		console.log 'route:404'.yellow
		yield return o.serveHttpCode 404


	admin: (o) ->
		console.log 'route:admin'.yellow
		{ session, template } = o

		template.templater = A.adminTemplater
		
		# TODO: ensure this works

		try
			try
				# Prepended to ensure the controller router scopes correctly
				o.path.controller = 'artic/' + o.path.controller
				
				if o.path.controller is 'artic/login'
					return yield routers.controller o
				
				if not user = yield session.auth()
					throw null
			catch err
				session.destroy()
				return o.serveRedirect '/artic/login'

			if not user.role.can.read.admin
				throw 'Insufficient permissions'
			
			return yield routers.controller o
		catch err
			return routers.error o, err

		yield return

	login: (o) ->
		console.log 'route:login'.yellow
		{ session, template } = o
		
		template.templater = A.adminTemplater

		try
			yield session.auth()
		catch err
			session.destroy()
			return o.serveRedirect '/admin/login'

		try
			yield A.controllers.admin.login o
		catch err
			return routers.error o, err
		
		o.serve()
		yield return