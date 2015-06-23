A		= require '../../app'
Promise	= require 'bluebird'

{ typeOf, merge, clone } = A.utils

module.exports = class Register extends A.modules.RestController
	create: (o) ->
		{ query, session, json } = o
		{ name, email, pass } = query

		return false # DISABLED AS FUCK
		
		role = undefined

		json.success = false

		if not email or not pass or not name
			throw 'Invalid email, password or username'

		user = yield A.db.Users()
			.where { email: email }
			.orWhere { name: name }
			.selectOne()

		if user
			if user.email?.toLowerCase() is email.toLowerCase()
				throw 'The email specified is already in use' # TODO: consider putting all of these error messages into settings

			if user.name?.toLowerCase() is name.toLowerCase()
				throw 'The username specified is already in use'

		# TODO: mimic webinar, but first create a user that can then be used as a default
		fields = A.db.Users()
			.count '* as count'
			.selectOne()

		adminRole = 2
		memberRole = 1

		# TODO: define a prop that designates something as "defaultMember" or "defaultAdmin" etc.
		role = if fields?.count and fields?.count < 1
			adminRole
		else
			memberRole

		insertedIds = yield A.db.Users().add {
			name # Will be sterilized
			email
			pass # Will be encrypted
			role: role or 1
		}

		if insertedIds?.length
			json.success = true
			session.create email
		else
			session.destroy()

		yield return

