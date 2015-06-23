A		= require '../../app'
Promise	= require 'bluebird'

{ typeOf, merge, clone } = A.utils

module.exports = class Categories extends A.modules.RestController
	create: (o) ->
		{ query, json, session } = o

		json.success	= false
		json.id			= null

		user = yield session.use()
		if not user.role.can.create.categories
			throw 'Insufficient permissions'

		if not query.name
			throw 'Invalid category name'

		if insertId = A.db.stores.categories.create query
			yield A.db.stores.categories.save()
		
			json.success	= true
			json.id			= insertId

		yield return

	read: (o) ->
		yield return

	update: (o) ->
		{ query, json, session } = o
		{ id } = query

		json.success	= false
		json.id			= null

		user = yield session.use()
		if not user.role.can.update.categories
			throw 'Insufficient permissions'

		if not id
			throw 'Invalid parameters; id missing'

		fields = merge.white {
			name: null, slug: null
			order: null, count: null
			parent: null
		}, query

		delete fields[key] for key, val of fields when val is null

		if fields.name and not fields.slug
			fields.slug = slugify fields.name

		if not Object.keys( fields ).length
			throw 'Invalid paremeters; no fields to update'
		
		if A.db.stores.categories.update id, fields
			yield A.db.stores.categories.save()

		json.success = true
		json.id = id

		yield return

	delete: (o) ->
		{ query, json, session } = o
		{ id } = query

		json.success	= false
		json.id			= null

		user = yield session.use()
		if not user.role.can.delete.categories
			throw 'Insufficient permissions'

		# TODO: permissions
		if not id
			throw 'Invalid parameters; id missing'

		if category = A.db.stores.categories.findOne { id }
			console.log 'delete category found', category
			if category.deletable is false
				json.error = "Category #{category.name} cannot be deleted"
				return null

			if A.db.stores.categories.delete category.id
				A.db.stores.categories.save()

			json.success	= true
			json.id			= id

		yield return
