###
	Database controller class for psuedo-Knex models.
	
	@version 0.3.0
###

Promise	= require 'bluebird'
Emitter	= require('events').EventEmitter
Knex	= require 'knex'

{ merge, clone, typeOf } = require 'lutils'

module.exports = class Database extends Emitter
	###
		The config is passed directly to Knex and
		any extra properties are used by the instance.
	
		@param cfg {Object}
			resetSchema	: false
			resetStores	: true
			
			client		: 'mariasql'
			debug		: false
			connection	:
				host	: 'localhost'
				charset	: 'utf8'
	###
	constructor: (@cfg = {})->
		super
		
		@models = {}
		@stores			=
		@models.stores	= {}
		
	initialize: (models) ->
		@add models if models

		@createConnection()
		yield @buildSchema()
		yield @buildStores()
		
		@emit 'ready'
		
		yield return
		
	createConnection: ->
		@knex = @knex or Knex @cfg
	
	###
		Adds models and store models to the instance.
	###
	add: (models) ->
		for key, Model of models when Model?.prototype?.constructor
			@[key] = @models[key] = @bindClass Model
		
		if models.stores
			@addStores models.stores
		
		return this
	
	addStores: (models) ->
		for key, Model of models when Model?.prototype?.constructor
			newKey				= key[0].toLowerCase() + ( key[1..] or '' )
			@stores[ newKey ]	= @bindClass( Model )()
		
		return this
	
	###
		Ensures a class will have @db, this, avaliable.
		
		@return		A function which does not require `new` keyword
					and creates a new instance of original class.
	###
	bindClass: (Class) ->
		self = this
		
		NewClass = class extends Class
			constructor: ->
				@db = self
				super
	
		return (args...) -> new NewClass args...
		
	###
		Builds up stores by merging database values with defaults while
		also allowing for stores to be reset to defaults.

		@return {Promise}
	###
	buildStores: ->
		await	= []

		if @cfg.resetStores
			incr = @cfg.resetDelay or 20

			yield new Promise (resolve, reject) =>
				@emit 'resetStores', incr

				interval = setInterval ( =>
					@emit 'resetStores.interval', incr

					if incr <= 0
						clearInterval interval
						resolve()

					--incr
				), 1000

			for key, store of @stores then do (key, store) =>
				await.push do Promise.coroutine =>
					# Saving with defaults
					yield store.save()
					@emit 'store.reset', store
		else
			for key, store of @stores then do (key, store) =>
				await.push do Promise.coroutine =>
					yield store.load()

					if store.defaults
						store.resetWithDefaults()
					
					yield store.save()
					
					@emit 'store.loaded', store

		yield Promise.all await

		return @stores

	###
		Builds up model database schema by initiating the define() function on
		each model where a table doesn't exist and dropping tables when a reset is specified.

		@return {Promise}
	###
	buildSchema: ->
		if @cfg.resetSchema
			incr = @cfg.resetDelay or 20

			yield new Promise (resolve, reject) =>
				@emit 'resetSchema', incr

				interval = setInterval ( =>
					@emit 'resetSchema.interval', incr

					if incr <= 0
						clearInterval interval
						resolve()

					--incr
				), 1000

		tables = []
		yield return Promise.map Object.keys( @models ), Promise.coroutine (key, index) =>
			Model = @models[ key ]

			return null if not Model?.prototype?.constructor

			model = new Model()

			return null if model.tableName in tables
			tables.push model.tableName

			if @cfg.resetSchema
				yield @knex.schema.dropTableIfExists model.tableName

				@emit 'table.dropped', model.tableName

			# Creates or modifies each model's table by calling their define() function
			exists = yield @knex.schema.hasTable model.tableName

			if not exists
				fn = if exists then 'table' else 'createTable'

				yield @knex.schema[ fn ] model.tableName, model.define

				tables.push model.tableName

				@emit 'table.created', model.tableName
				
				yield model.insertDefaults?() if model.defaults

			return true
	
	require('coroutiner') @prototype
