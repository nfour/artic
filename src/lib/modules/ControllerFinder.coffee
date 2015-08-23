###
	Controller Finder.
	Searches a nested object structures for properties matching
	a set of keys (as derived from a url), finally calling a controller.
	
	Searches wich keys end up resolving to either a Function
	or instance of RestController are accepted.

	@version 0.1.0
###

RestController = require './RestController'

{ typeOf } = require 'lutils'

module.exports = class ControllerFinder
	constructor: (@position) ->
		@controller = null
		
	keyOf: (key, @position) ->
		return _key for _key of @position when key.toLowerCase() is _key.toLowerCase()
		return false

	find: (keys) ->
		for key in keys when actualKey = @keyOf key, @position
			@position = @position[ actualKey ]

			if @evaluate @position
				@controller = @position

		return if @controller?.prototype instanceof RestController
			new @controller().crud
		else
			@controller

	evaluate: (controller) -> controller.prototype instanceof RestController or typeOf.Function controller
