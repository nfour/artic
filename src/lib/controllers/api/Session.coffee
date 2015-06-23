A		= require '../../app'
Promise	= require 'bluebird'

{ typeOf, merge, clone } = A.utils

module.exports = class Session extends A.modules.RestController
	###
		email		: 'some@email.com'
		pass		: 'password plaintext'
		redirect	: 'whereToRedirect' (optional)
	###
	create: (o) ->
		{ query, session, json } = o
		{ email, pass, redirect } = query

		if redirect
			o.redirect = redirect

		if not ( email and pass )
			throw 'Invalid email or password'

		if not user = yield A.db.Users().where({ email }).selectOne()
			throw 'User not found'

		if not new A.modules.Crypto().validateHash user.hash, user.salt, pass
			throw 'Invalid password'

		json.success = !! session.create user

		yield return

	read: (o) ->
		{ session, json } = o

		yield session.auth()

		json.data = session.data

		yield return
	
	update: (o) ->
		{ session } = o

		yield session.use()

		yield return

	delete: (o) ->
		{ session, json } = o

		json.success = session.destroy()
		yield return