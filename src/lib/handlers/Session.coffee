A = require '../app'

{ merge, clone, typeOf } = A.utils

# TODO: ensure the A.modules version is usable or modifiable
module.exports = class Session
	constructor: (o) ->
		@cookies	= o.cookies
		@keys		= A.cfg.keys or [ 'x' ] # todo: standardize the use of keys to rotate, such as A.keys and A.cfg.keys
		
		@user = null
		@data = if session = @cookies.get 'session'
			@decode session
		else
			null

	auth: ->
		return null if not @data # No session
		try
			if not user = yield @getUser()
				throw 'Session user not found'

			@validate user
		catch err
			@destroy()
			throw err

		yield return user

	getUser: ->
		yield return if @user?
			@user
		else
			@user = yield A.db.Users()
				.where { id: @data?.id }
				.selectOne()

	use: ->
		try
			if user = yield @auth()
				@create user
				return user
		catch err
			@destroy()
		
		yield return null

	create: (user) ->
		now		= new Date().getTime()
		days	= A.cfg.session?.expiry or ( 30 * 3600 * 60 * 60 * 24 )
		expiry	= new Date now + days

		try
			@data =
				id		: user.id
				hash	: user.hash
				time	: now

			@cookies.set 'session', @encode( @data ), { signed: false, expires: expiry }
		catch err
			@destroy()
			throw 'Session creation failure'

		return @data

	validate: (user) ->
		if not user?.id
			throw 'User not found'

		if user?.hash isnt @data?.hash
			throw 'Invalid session credentials'

	encode: (data = @data) ->
		return new A.modules.Crypto().cipher JSON.stringify( data ), @keys[0]

	decode: (str) ->
		# todo: for key in @keys decipher for each then if it's not the first key, reset the session with the latest key
		try
			try
				val = new A.modules.Crypto().decipher str, @keys[0]
			catch err
				A.emit 'error', new Error 'Warning: Broken session decryption for value: ' + str
				throw err

			try
				return JSON.parse val
			catch err
				A.emit 'error', new Error 'Warning: Broken JSON.parse for value: ' + val
				throw err

		catch err
			@destroy()

		return null

	destroy: ->
		console.log 'destroying session'.red, @data
		state = !! @data

		@cookies.set 'session', null
		@data = null

		return state