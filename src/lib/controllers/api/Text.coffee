A		= require '../../app'
Promise	= require 'bluebird'

{ typeOf, merge, clone } = A.utils

module.exports = class Text extends A.modules.RestController
	create: (o) ->
		yield return

	read: (o) ->
		yield return

	update: (o) ->
		{ query, json, session } = o
		{ id, value } = query

		json.success	= false
		json.id			= null

		user = yield session.use()
		if not user.role.can.update.text
			throw 'Insufficient permissions'

		if not id
			throw 'Invalid parameters; id missing'

		if A.db.stores.text.update id, { value }
			yield A.db.stores.text.save()

		json.success = true
		json.id = id
		
		yield return

	delete: (o) ->
		yield return
