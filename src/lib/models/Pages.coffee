A			= require '../app'
Articles	= require './Articles'
Promise		= require 'bluebird'

{ merge, clone, typeOf } = A.utils

###
	This is a proxy model to Articles. It just midifies default settings and fiddles with functions
	but is merely using the Articles table.
###
module.exports = class Pages extends Articles
	constructor: ->
		super

		merge @o,
			page: true

	formatInput: (rows) ->
		for fields in rows
			fields.page = true

		return yield super rows