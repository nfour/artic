###
	A knex-based Model base class.
	
	`@db` is a Knex() connection. It can be passed
	as the first argument or bound another way (as with Database).

	@version 0.6.1
###

Promise	= require 'bluebird'
Emitter	= require('events').EventEmitter

{ merge, clone, typeOf, format } = require 'lance/utils'

module.exports = class Model extends Emitter
	validators: {}
	
	constructor: (args...) ->
		super
		
		if args.length > 1
			@db = args[0]
		
		# The last argument are options
		o = args[ args.length - 1 ]

		predefined = @o or @params or {}
		@o = @params = merge.black predefined,
			wheres	: []
			columns	: []
			knex	: []
			fields	: undefined
			select	: false
			update	: false
			delete	: false
			insert	: false
	
		merge @o, o if o
		
		@table		= @db.knex @tableName
		@validated	= false
		
	
	# Used but deprecated, need to rewrite knex models
	rawEscape: (item, bindings) ->
		if typeOf.Array item
			for val, index in item
				binding = bindings?[index] or null
				item[index] = @db.knex.raw SqlString.escape( val ), binding

			return item
		else
			return @db.knex.raw SqlString.escape( item ), bindings

	# Used but deprecated, need to rewrite knex models
	raw: (args...) -> @db.knex.raw args...

	select: ->
		@inject()

		rows = yield @table
		
		#console.log 'select'.yellow, JSON.stringify rows, null, 4

		return yield @formatOutput rows

	selectOne: ->
		@table.limit 1
		yield return ( yield @select.apply this, arguments )?[0] or null

	update: (fields) ->
		fields ?= @o.fields

		yield @formatInput [ fields ]
		yield @validate fields

		#console.log 'update'.yellow, JSON.stringify [ fields ], null, 4

		@table.update fields
		@inject()

		return yield @table

	insert: (rows) ->
		rows ?= @o.fields
		rows = @castInput rows
		
		yield @formatInput rows
		yield @validate rows
		
		return [] if not rows.length
		
		#console.log 'insert'.yellow, JSON.stringify rows, null, 4
		
		@table.returning('id').insert rows
		@inject()

		return yield @table

	delete: ->
		@inject()
		@table.delete()
		#console.log 'delete'.yellow, JSON.stringify @o, null, 4

		return yield @table

	formatOutput: (rows) ->
		yield return rows

	formatInput: (rows) ->
		for fields in rows
			format.jsonify fields

		yield return rows

	insertDefaults: ->
		rows = @defaults
		#console.log 'insertDefaults', rows

		return null if not rows?.length

		yield @formatInput rows
		#console.log 'insert defaults'.yellow, JSON.stringify rows, null, 4
		@table.returning('id').insert rows
		@inject()

		return yield @table

	castInput: (rows) -> if not typeOf.Array rows then [ rows ] else rows

	###
		Validates fields based on a @validation object
		
		Functionality:
			- A field whitelist
				Any fields not of the validator are invalidated.

			- Validate values by throwing errors
				Throwing an error in a validator function invalidates a field.

			- Transform values
				A validators return value becomes the new value


		A validator can be:
			- true or false
				Check whether the value is truethy or not.

			- null
				No validation occurs beyond whitelisting
			
			- GeneratorFunction (value, key, row) ->
				A yielding Promise.coroutine.
				Thrown errors invalidate the field. Returned value replaces the old.
				`this` is the parent class.
				
		This class will emit an `invalid` event for each invalid field.
		@on 'invalid', ({ row, field, reason }) ->

		@param rows {Array or Object} A row or array of rows
		@return rows {Array or Object} Same format as input
	###
	validate: (rows) ->
		return rows if not @validation
		
		rows = @castInput rows

		for row, index in rows by -1
			invalids = []

			for field of row when field not of @validation
				delete row[ field ]

			for field, validator of @validation when field of row and validator?
				value = row[ field ]

				switch
					when validator is true or validator is false
						if ( !! value ) isnt validator
							invalids.push { row, field, reason: "Expected #{ validator.toString() }-like value" }
					when typeOf.Function validator
						yield validator.apply this, [ value, field, row ]
						.then (value) =>
							row[ field ] = value
						.catch (err) =>
							throw err if err instanceof Error

							invalids.push { row, field, reason: err }

			if invalids.length
				for invalid in invalids
					@emit 'invalid', invalid
					rows.splice index, 1
					
		yield return if rows is arguments[0] then rows else rows[0]
	
	require('coroutiner') @prototype
	
	#
	# Knex passthrough
	#

	###
		Injects options from @o into the @table (knex) instance.
	###
	inject: (table = @table, o = @o) ->
		for param in o.wheres
			table[ param.fn ].apply table, param.arguments

		if o.columns.length
			table.column.apply table, o.columns

		if o.knex.length
			for param in o.knex
				table[ param.fn ].apply table, param.arguments

		return table

	columns: (args...) ->
		@o.columns = if typeOf.Array args[0]
			@o.columns.concat args[0]
		else
			@o.columns.concat args

		return this

	fields: (fields) ->
		if typeOf.Object @o.fields
			@o.fields = merge @o.fields, fields
		else
			@o.fields = fields

		return this
		
	knexProperties =
		wheres: [
			'where', 'whereRaw', 'whereExists', 'whereIn', 'whereNull'
			'whereBetween', 'whereNotExists', 'whereNotNull', 'whereNotIn'
			'andWhere', 'andWhereIn', 'whereRaw', 'whereExists', 'whereNull'
			'whereBetween', 'whereNotExists', 'whereNotNull', 'whereNotIn'
			'orWhere', 'orWhereIn', 'orWhereRaw', 'orWhereExists', 'orWhereNull'
			'orWhereBetween', 'orWhereNotIn', 'orWhereNotNull', 'orWhereNotExists'
		]
		
		functions: [
			'limit', 'join', 'distinct', 'groupBy', 'orderBy'
			'having', 'offset', 'union', 'debug', 'options'
			'transacting', 'min', 'max', 'sum'
			'forUpdate', 'forShare', 'count'
			'increment', 'decrement', 'truncate', 'debug', 'returning'
			['select', '_select'], ['update', '_update']
			['insert', '_insert'], ['delete', '_delete']
		]
		
	###
		Adds Knex functions which act as passthrough for ijection later
		# TODO: use the prototype from knex/src/query/builder
		# ignoring anything starting with _, any wheres, and any props already set in this.
	###
	for args in knexProperties.functions then do (args) =>
		args = [args] if typeof args is 'string'

		knexFn = args[0]
		newFn = args[1] or knexFn

		@::[newFn] = ->
			@o.knex.push { fn: knexFn, arguments }
			return this
			
	###
		Specifically add wheres seperately
	###
	for fn in knexProperties.wheres then do (fn) =>
		@::[fn] = ->
			@o.wheres.push { fn, arguments }
			return this
			
