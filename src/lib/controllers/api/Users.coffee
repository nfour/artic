A		= require '../../app'
Promise	= require 'bluebird'

{ typeOf, merge, clone } = A.utils

module.exports = class Users extends A.modules.RestController
	create: (o) ->
		{ query, json, session } = o
		json.id = null

		user = yield session.use()
		if not user.role.can.create.users
			throw 'Insufficient permissions'

		if insertIds = yield A.db.Users().create query
			json.id = insertIds[0]

		yield return


	read: (o) ->
		yield return

	update: (o) ->
		yield return


	delete: (o) ->
		{ json, query, session } = o
		{ id } = query

		id = parseInt id

		if not id
			throw "Invalid user id"

		user = yield session.use()
		if not user.role.can.delete.users
			throw 'Insufficient permissions'

		if json.id = yield A.db.Users().where({ id }).limit(1).delete()
			json.success = true

		yield return
