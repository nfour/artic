###
	Cache.
	Stores data in memory with timeout purging etc.
	
	@version 0.1.0
###

{ clone, merge, typeOf } = require 'lutils'

module.exports = class Cache
	constructor: (cfg) ->
		@defaultTimeout	= 1000 * 60 * 60
		@count			= 0
		@size			= 0
		@threshold		= 1000
		@truncate		= 50
		@data			= []
		@map			= {}

		merge this, cfg if cfg

	thresholdHandler: ->
		if @count >= @threshold
			@truncate()

	truncate: (limit = @truncate) ->
		count = 0
		for item, index in @data by -1
			break if ++count >= limit

			@delete item.key

		return this

	create: (key, value, timeout) ->
		if not @isSet key
			@data.push { key, value }
			@resetMap()
			@setTimeout key, timeout if timeout

	delete: (key) ->
		if ( index = @map[key] ) isnt undefined
			@clearTimeout key
			@data.splice index, 1
			@resetMap()
			return true

		return false

	resetMap: ->
		delete @map[key] for key of @map

		for item, index in @data
			@map[ item.key ] = index

		return this

	purge: (search) ->
		for mapKey in @find search, true
			@delete mapKey

		@resetMap()

	get: (key) -> return @data[ @map[key] ]?.value or undefined

	isSet: (key) -> return @map[ key ] isnt undefined

	set: (key, value, timeout) ->
		if typeOf.Object key
			{ key, value, timeout } = key

		@thresholdHandler()

		if @isSet key
			@clearTimeout key

		@create key, value, timeout

		return true

	find: (key, returnKeys) ->
		results = []
		if typeOf.RegExp key
			for mapKey of @map when mapKey.match key
				results.push if returnKeys then mapKey else @data[ @map[ mapKey ] ]
		else
			if @isSet key
				results.push if returnKeys then key else @data[ @map[ key ] ]

		return results

	clearTimeout:(key) ->
		clearTimeout @data[ @map[key] ].timeout

	setTimeout: (key, time = defaultTimeout) ->
		@clearTimeout key

		@data[ @map[key] ].timeout = setTimeout ( =>
			@delete key
		), time

	# TODO: write a memory estimation function, run it over each new set value, 
	# allow for maxSize and culling till it's arbitrarily half the size or
	# perhaps also interface with node evn variable, determine the upper limit and work within it
