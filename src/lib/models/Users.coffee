A		= require '../app'
Base	= require '../modules/models/Model'
Promise	= require 'bluebird'

{ merge, typeOf, clone } = A.utils

module.exports = class Users extends Base
	tableName	: 'users'
	defaults	: A.data.defaults.users
	
	validation:
		createdAt	: true
		updatedAt	: true
		name		: true
		slug		: true
		email		: true
		hash		: true
		salt		: true
		role		: true
		data		: null
		disabled	: null

	auth: (email, pass) ->
		try
			user = yield @db.Users()
				.columns 'id', 'email', 'hash', 'salt'
				.where { email }
				.selectOne()
		catch err
			@emit 'error', err
			throw 'Database error while authenticating user'

		if not user
			throw 'User not found'

		{ hash, salt } = user

		newHash = new A.modules.Crypto().hash pass, salt

		yield return if newHash is hash then user else null

	create: (fields) ->
		{ name, email, pass } = fields

		if not ( A.utils.format.validateEmail( email) and pass )
			throw 'Invalid email or pass'

		if oldUser = yield @db.Users().where( { email } ).selectOne()
			throw "User already exists with email `#{email}`"

		fields.createdAt =
		fields.updatedAt = new Date().getTime()

		return yield @insert fields

	formatInput: (users) ->
		for user in users
			{ name, email, pass, slug, role } = user

			if name?
				user.name = A.utils.format.sanitizeUsername name

				if not slug
					user.slug = A.utils.format.slugify user.name

			if not ( A.utils.format.validateEmail( email ) )
				throw 'Invalid user email'

			if pass?
				if not pass
					throw 'Invalid user password'

				[ user.hash, user.salt ] = new A.modules.Crypto().encrypt pass

				if not ( user.hash and user.salt )
					throw 'User password encryption failure'

			if role?
				if @db.stores.userRoles? and not @db.stores.userRoles.findOne { id: role }
					throw 'Unknown/invalid user role specified'

				user.role = parseInt role

		return yield super users

	formatOutput: (rows) ->
		for user in rows
			user.role = @db.stores.userRoles.readOne { id: user.role }

		return yield super

	define: (table) ->
		table.increments	'id'
			.primary()

		table.bigInteger	'createdAt'
			.defaultTo(0)
		table.bigInteger	'updatedAt'
			.defaultTo(0)

		table.integer		'role',			1

		table.string		'name',			64
			.index()
		table.string		'slug',			64
			.index()
		table.string		'email',		255
			.index()

		table.string		'hash',			255
		table.string		'salt',			255

		table.boolean		'disabled'
			.notNullable()
			.defaultTo false
			.index()

		table.text			'data',			'mediumtext'

		return table
