fs		= require 'fs'
path	= require 'path'
Emitter	= require('events').EventEmitter

{ merge, clone, typeOf } = require 'lutils'


###
	Store base class.
	Stores are in-memory data stores for high-performance reads.
	By default persistant to @db.Stores() model.
	
	@version 0.1.0
###
module.exports = class Store extends Emitter
	constructor: ->
		super
		
		@values = if @valueKey then {} else @data

	load: ->
		fields = yield @loader()

		if fields
			saveData = fields.value
			@reset saveData

			return saveData

		yield return

	save: ->
		saveData = JSON.stringify @saveData
		return yield @saver saveData
		
	loader: ->
		@db.Stores()
		.where { @key }
		.selectOne()
	
	saver: (saveData) ->
		@db.Stores().set @key, saveData
	
	reset: (saveData) ->
		@resetData saveData.data
		@resetMeta saveData.meta
		@calcMeta()
		@resetValues @data

		return this

	resetValues: (newData = {}) ->
		if @valueKey
			delete @values[key] for key of @values
			
			for key, val of newData
				@values[key] = val[ @valueKey ]

		return this

	# todo: currently unused, but should be as calling resetValues is too much for just update some or one value
	updateValues: (newData = {}) ->
		if @valueKey
			merge @values, newData

	updateValue: (key, val) ->
		if key is @valueKey
			@values[ key ] = val

	validateFields: (fields = {}) ->
		for key, val of fields when key not of @fields
			delete fields[key]

		return fields
		
	whitelist: (fields = {}) ->
		return merge.white clone( @fields ), fields
		
	require('coroutiner') @prototype