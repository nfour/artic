###
	Artic
	
	This is the base file which glues everything together.
	The entire ./lib/* directory is attatched to this exported function.
	
	A.initialize() then initializes artic with a database, templating and lance/server.
	
	./src/ structure explained:
	
	./src/lib/
		Contains immutable functionality.
		
	./src/lib/modules
		Any file in here should be considered almost-completely application agnostic.
		The only reason it isn't a node_module is because that would be too restricting.
		
		These may depend on eachother and even some basic singleton structure in rare cases
		but nothing more.
		
	./src/lib/controllers/
		Controllers called upon by /lib/handlers/routers.
		Controllers are dynamically read upon by the routers based on path
		which esnures a new controller can simply be added to the folder
		and it will just work.
		
		Some controllers extend from /lib/modules/RestController which supplies a CRUD
		class interface. All controllers are selected through /lib/modules/ControllerFinder
	
	./src/lib/models/
		Models. Follows this structure
		{ Model: class Model extends /lib/modules/models/Model, stores: { class Store extends /lib/modules/models/Store } }
		
		SQL based models are constructed on demand and are automatically bound to a database instance
		when accessed from the A.db /lib/modules/models/Database instance.
		Store models, found in /lib/models/stores are constructed only once and persist in memory.
		
		Models are dynamically read thus a new file of the correct structure means a new model.
	
	./src/lib/handlers
		Contains files that handle things, helpers, misc stuff etc.
		If it doesnt fit directly in /lib/ or any subfolder, then it goes in here.

	./src/templates/
		Templates for the default themes and the admin theme/interface.
		
		These assets will be used to construct a template directory in the user's project.
		This should all *idealy* be overridable by the user's own directory structure on
		a file by file basis. Currently is it workable but unfinished.
###

path		= require 'path'
requireDir	= require 'require-directory'
Promise		= require 'bluebird'
Lance		= require 'lance'
Emitter		= require('events').EventEmitter
require 'colors'

module.exports = A = (cfg) ->
	Emitter.call A
	
		
	merge A.cfg, cfg if cfg
	
	A.paths =
		root			: rootDirectory = A.cfg.root or path.dirname require.main.filename
		artic			: articDirectory = path.dirname __dirname
		static			: staticDirectory = A.cfg.staticDirectory or path.join rootDirectory, './static'
		adminStatic		: path.join staticDirectory, './admin'
		database		: path.join rootDirectory, A.cfg.database.connection.filename
		
	A.cfg.database.connection.filename = A.paths.database
	
	A.lance = new Lance A.cfg.lance
	A.lance.eventHandler.relay A # Relays events from lance to this
	A.cfg.Promise?.onPossiblyUnhandledRejection A.lance.onPossiblyUnhandledRejection

	A.router	= A.lance.router
	A.db		= new A.modules.models.Database A.cfg.database

	A.handlers.events()
	
	A.emit 'init'
		
	return A

A.initialize = ->
	#
	# DATABASE
	# All A.models[model] will have @db avaliable in each constructed instance, including stores
	#

	# Builds SQL Schema and also constructs A.models.stores models
	yield A.db.initialize A.models
	
	#
	# TEMPLATING
	#
	
	yield A.handlers.templating()
	
	#
	# SERVER, TEMPLATER ETC.
	#
	
	A.handlers.routing()
	
	yield A.lance.initialize()
	

{ clone, merge }	=
A.utils				= require './utils'

merge A, Emitter.prototype

###
	A coroutiner instance which will penetrate everything
	to ensure ALL GeneratorFunction's become Promise.coroutine's
###
A.coroutiner	= new require( 'coroutiner' ).Coroutiner { array: true, prototype: true, Promise }
A.data			= data = requireDir module, '../data'
A.cfg			= clone data.cfg

A.modules = requireDir module, './modules'

merge A, requireDir module, './', { exclude: /// /_[^/]+$ /// }

A.coroutiner.all A
