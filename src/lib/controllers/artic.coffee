A		= require '../app'
Promise	= require 'bluebird'

{ merge, typeOf, clone } = A.utils

module.exports = controller = (o) ->
	{ path, template, session } = o
	{ page } = path or {}
	{ data } = template

	template.view		= 'home'
	page				?= 1

	template.data.user = yield session.use()
	yield return

merge controller,
	login: (o) ->
		{ template, session } = o

		template.view		= 'login'
		console.log A.templater.cfg.root
		yield return

	articles: (o) ->
		{ path, json, query, session, template } = o

		user = yield session.use()
		if not user.role.can.read.adminArticles
			throw 'Insufficient permissions'

		query = merge.white {
			page	: 1
			limit	: 40 # use a settings variable for this
			render	: true
			view	: 'sections/articles'
		}, query

		query.limit = parseInt query.limit

		# TODO: add params for constructing the WHERE, date etc.

		if not user = yield session.use()
			# todo: user permissions
			console.log 'unauthorized access'.red

		articles = yield A.db.Articles()
			.limit query.limit
			.select { disabled: true, private: true, unpublished: true }

		pagination = null # todo: pagination!

		if query.render
			json.html = yield A.adminTemplater.render query.view, { articles, pagination }
		else
			json.data = article
	
		yield return

	articlesList: (o) ->
		merge o.query, {
			view: 'parts/articlesList'
			render: false
		}

		yield return controllers.articles o

	pages: (o) ->
		{ path, json, query, session, template } = o

		user = yield session.use()
		if not user.role.can.read.adminPages
			throw 'Insufficient permissions'

		query = merge.white {
			page	: 1
			limit	: 40 # use a settings variable for this
			render	: true
			view	: 'sections/articles'
		}, query

		query.limit = parseInt query.limit

		# TODO: add params for constructing the WHERE, date etc.

		if not user = yield session.use()
			# todo: user permissions
			console.log 'unauthorized access'.red

		articles = yield A.db.Pages()
			.limit query.limit
			.debug()
			.select { disabled: true, private: true, unpublished: true }

		pagination = null # todo: pagination!

		console.log 'route: pages'.red

		if query.render
			json.html = yield A.adminTemplater.render query.view, { articles, pagination }
		else
			json.data = article

		yield return

	pagesList: (o) ->
		merge o.query, {
			view: 'parts/articlesList'
			render: false
		}

		yield return controllers.pages o

	article: (o) ->
		{ path, json, query, session } = o

		user = yield session.use()
		if not user.role.can.read.adminArticles
			throw 'Insufficient permissions'

		query = merge.white {
			id		: null
			render	: true
			view	: 'parts/article'
		}, query

		articleId = parseInt query.id

		if not articleId
			throw 'Invalid Article id' # todo: standardize this msg

		if not user = yield session.use()
			# todo: user perms
			console.log 'unauthorized access'.red

		article = yield A.db.Articles()
			.where { id: articleId }
			.selectOne { disabled: true, private: true, unpublished: true, page: undefined }
			
		console.log 'route: single article'.red

		if query.render
			json.html = yield A.adminTemplater.render query.view, { article }
		else
			json.data = article

		# todo: (old) build up this controllers, let it work for both the article preview
		# maybe make articleEdit so that it allows for finer control, security, only after this one is done and it's clear its necessary
		# then build the edit tab, page, api etc., get hashbangs working so you can query it easily to test.
		yield return

	settings: (o) ->
		{ path, json, query, session } = o
		data = {}

		user = yield session.use()
		if not user.role.can.read.adminSettings
			throw 'Insufficient permissions'

		query = merge.white {
			page	: 1
			limit	: 999
			render	: true
			view	: 'sections/settings'
		}, query

		settings = A.db.stores.settings.read()
		groups = {}

		for key, obj of settings
			group = obj.group or '*'
			groups[ group ] = {} if not groups[ group ]
			groups[ group ][ key ] = obj

		data.items = settings
		data.itemsByGroup = groups

		if query.render
			json.html = yield A.adminTemplater.render query.view, data
		else
			json.data = data

		yield return

	text: (o) ->
		{ path, json, query, session } = o
		data = {}

		user = yield session.use()
		if not user.role.can.read.adminText
			throw 'Insufficient permissions'

		query = merge.white {
			page	: 1
			limit	: 999
			render	: true
			view	: 'sections/text'
		}, query

		texts = A.db.stores.text.read()
		groups = {}

		for key, obj of texts
			group = obj.group or '*'
			groups[group] = {} if not groups[group]
			groups[group][key] = obj

		data.items = texts
		data.itemsByGroup = groups

		# todo: settings by group
		# construct data object

		if query.render
			json.html = yield A.adminTemplater.render query.view, data
		else
			json.data = data

		yield return

	categories: (o) ->
		{ path, json, query, session } = o
		data = {}

		user = yield session.use()
		if not user.role.can.read.adminCategories
			throw 'Insufficient permissions'

		query = merge.white {
			page	: 1
			limit	: 999
			render	: true
			view	: 'sections/categories'
		}, query

		data.categories = A.db.stores.categories.read()

		if query.render
			json.html = yield A.adminTemplater.render query.view, data
		else
			json.data = data

		yield return

	users: (o) ->
		{ json, template, query, session } = o
		{ data } = template

		data.user = user = yield session.use()
		if not user.role.can.read.adminUsers
			throw 'Insufficient permissions'

		{ page, render, view } = query

		page	= parseInt page
		render	?= true # todo: parse this into a boolean
		view	= view or 'sections/users'

		data.users = yield A.db.Users().limit(40).select({ disabled: true }) # todo: add pagination and .where() for searches

		if render
			json.html = yield A.adminTemplater.render view, data
		else
			json.data = data

		yield return
