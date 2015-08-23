###
	Store Base.ObjectData base class.
	Stores data in a hashtable object.
	
	@version 0.2.0
###

Store = require './Store'

{ merge, clone, typeOf } = require 'lutils'

module.exports = class ObjectData extends Store
	constructor: ->
		@saveData =
			data: @data = {}
			meta: @meta =
				count			: 0
				autoIncrement	: 0
	
		super

		if @defaults
			merge.black @defaults, @saveData # Add any missing meta to the defaults
			@reset clone @defaults

	create: (key, fields) ->
		if key not of @data
			@data[ key ] = fields
			@resetValues @data

			return ++@meta.count

		return false

	read: (where) ->
		if not where?
			results = @formatOutput @data
		else
			if ( results = @find where ).length
				results = @formatOutput results

		return results

	formatOutput: (data) -> return clone data

	readOne: -> @read.apply( this, arguments )?[0]

	update: (where, val) ->
		if key = @findOne where, { key: true }
			if typeOf.Object val
				merge.white @data[ key ], val
			else
				@data[ key ] = val

			@resetValues @data

			return true

		return false

	delete: (where) ->
		if key = @findOne where, { key: true }
			delete @data[ key ]
			--@meta.count

			@resetValues @data

			return true

		return false

	set: (key, val) ->
		return if key of @data
			@update { key }, val
		else
			@create key, val
	
	find: (where, o = {}) ->
		results		= []
		foundKeys	= []

		return results if not where

		switch typeOf where
			when 'object'
				for needleKey, needleVal of where
					for key, obj of @data
						continue if needleKey not of obj or key in foundKeys

						val = obj[needleKey]

						switch typeOf val
							when 'number'
								needleVal	= parseInt needleVal
							when 'string'
								val			= val.toLowerCase()
								needleVal	= needleVal.toLowerCase()

						if needleVal is val
							foundKeys.push key
							results.push if o.key then key else obj
			when 'array'
				for needle in where
					if _results = @find needle, o
						results = results.concat _results

			else
				results.push if o.key then where else @data[ where ]

		return results

	findOne: -> @find.apply( this, arguments )?[0]

	resetData: (newData = {}) ->
		delete @data[key] for key of @data
		@data[key] = val for key, val of newData

		return this

	resetMeta: (newMeta) ->
		delete @meta[key] for key of @meta
		@meta[key] = val for key, val of newMeta

		return this

	calcMeta: ->
		@meta.count = 0
		++@meta.count for own key of @data

		if @meta.count > @meta.autoIncrement
			@meta.autoIncrement = @meta.count
		
		return this

	resetWithDefaults: (newSaveData = @saveData) ->
		@reset merge clone( @defaults ), newSaveData
