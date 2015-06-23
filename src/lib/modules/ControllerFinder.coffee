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
