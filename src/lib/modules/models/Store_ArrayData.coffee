###
	Store Base.ArrayData base class.
	Stores data as rows in an array.
	
	@version 0.2.0
###

Store = require './Store'

{ merge, clone, typeOf } = require 'lutils'

module.exports = class ArrayData extends Store
	constructor: ->
		@saveData =
			data: @data = []
			meta: @meta =
				count			: 0
				autoIncrement	: 0
	
		super

		if @defaults
			merge.black @defaults, @saveData # Add any missing meta to the defaults
			@reset clone @defaults

	create: (row) ->
		@data.unshift row

		++@meta.count
		return row

	read: (where) ->
		if not where?
			results = @formatOutput @data
		else
			if ( results = @find where ).length
				results = @formatOutput results

		return results

	readOne: -> @read.apply( this, arguments )?[0]

	update: (where, val) -> # todo: make it work for arrays, as its copypasted
		if key = @findOne where, { key: true }
			if typeOf.Object val
				merge @data[key], val
			else
				@data[key] = val
			
			return true

		return false

	delete: (where) ->
		if index = @findOne where, { key: true }
			@data.splice index, 1
			--@meta.count

			return true

		return false

	formatOutput: (rows) -> return clone rows

	# TODO: improve this function by iterating only once over the rows
	# and instead iterating over every row for each where, if array
	find: (where, o = {}) ->
		results		= []
		foundKeys	= []

		return results if not where

		switch typeOf where
			when 'object'
				for row, index in @data
					for needleKey, needleVal of where
						continue if needleKey not of row or index in foundKeys

						val = row[needleKey]

						switch typeOf val
							when 'number'
								needleVal	= parseInt needleVal
							when 'string'
								val			= val.toLowerCase()
								needleVal	= needleVal.toLowerCase()

						if needleVal is val
							foundKeys.push index
							results.push if o.key then index else row
			when 'array'
				for needle in where
					if _results = @find needle, o
						results = results.concat _results

			else
				results.push if o.key then where else @data[ where ]

		return results

	findOne: -> @find.apply( this, arguments )?[0]

	resetData: (newData) ->
		@data.pop() while @data.length > 0
		@data.push item for item in newData

		return this

	resetMeta: (newMeta) ->
		delete @meta[key] for key of @meta
		@meta[key] = val for key, val of newMeta

		return this

	calcMeta: ->
		@meta.count = @data.length
		
		if @meta.count > @meta.autoIncrement
			@meta.autoIncrement = @meta.count

		return this

	resetWithDefaults: (newSaveData = @saveData) ->
		saveData = clone @defaults

		data	= saveData.data
		newData	= newSaveData.data

		for item, index in newData
			if index of data
				data[ index ] = merge item, newData[ index ]
			else
				data.push item

		return @reset saveData


