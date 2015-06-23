A		= require '../../app'
Promise	= require 'bluebird'

{ typeOf, merge, clone } = A.utils

module.exports = class Uploads extends A.modules.RestController
	create: (o) ->
		{ query, json, session } = o
		{ name, file, url } = query

		if file
			1
		else if url
			try
				[  ] = yield request {
					url: url
					encoding: null
				}
			catch err
				throw 'Invalid url'

		#randomStr = A.classes.Crypto().random 3
		yield return

	read: (o) ->
		yield return

	update: (o) ->
		yield return

	delete: (o) ->
		yield return
