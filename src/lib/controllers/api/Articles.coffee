A		= require '../../app'
Promise	= require 'bluebird'

{ typeOf, merge, clone } = A.utils

module.exports = class Articles extends A.modules.RestController
	create: (o) ->
		{ query, json, session } = o
		{ page, pageKey } = query

		json.success = false

		user = yield session.use()
		if not user.role.can.create.articles
			throw 'Insufficient permissions'

		fields = clone query

		# Create a title slug
		fields.slug = if fields.customSlug and fields.slug
			fields.slug
		else
			A.utils.format.slugify fields.title

		if not fields.slug
			throw 'The article has an invalid title or title slug'

		Model = if parseInt( page ) > 0 then A.db.Pages else A.db.Articles

		oldArticle = yield Model()
			.where { slug: fields.slug }
			.column 'articles.id'
			.selectOne { private: true, disabled: true, raw: true }

		if oldArticle?.id
			throw "An article with the title slug `#{fields.slug}` already exists"

		fields.author = user.id

		insertedIds = yield Model().insert fields

		if not articleId = insertedIds[0]
			throw 'Failed to commit article to database'

		json.id = articleId

		#
		# Construct Article Meta
		#

		# We always commit meta entries so to consistantly overwrite

		metaEntries = [
			A.handlers.models.parseCategoryIdInput query.categories
			yield A.handlers.models.parseAndCommitTagNameInput query.tags
		]

		entry.articleId	= articleId for entry in metaEntries

		if not json.metaIds = yield A.db.ArticlesMeta().insert metaEntries
			# Deletes the recently committed article due to the error
			yield Model()
				.where { id: articleId }
				.delete()

			throw 'Failed to commit article metadata to database'

		json.success = true
		yield return

	read: (o) ->
		{ query, json, session } = o
		{ count, page, categories } = query

		user = yield session.use()
		if not user.role.can.read.articles
			throw 'Insufficient permissions'

		count = ( parseInt count ) or 20
		page = ( parseInt page ) or 1

		# code pagination here to determine limit + offset

		query = A.db.Articles()

		# "categories" which defaults to json, which needs to eval to [ { slug: '', id: '' } ]
		if typeOf.Array categories
			categories
			# need to do some join sql stuff first

		#json.data = yield query.select()
		#json.success = true
		yield return

	update: (o) ->
		{ query, json, session } = o
		{ page } = query

		articleId		= parseInt query.id
		json.success	= false

		if not articleId
			throw 'Invalid parameters; invalid article id'

		if not query.title and not query.slug
			throw 'Invalid parameters; title and slug are empty'

		#if page and not pageKey
		#	throw 'Invalid parameters; pageKey was empty'

		Model = if parseInt( page ) > 0 then A.db.Pages else A.db.Articles

		oldArticle = yield Model()
			.where { id: articleId }
			.selectOne { disabled: true, private: true, unpublished: true }

		if not oldArticle?.id
			throw "Article not found by id `#{articleId}`"

		articleId = oldArticle.id

		user = yield session.use()

		if not (
			user.role.can.update.articles or (
				user.role.can.update.owned.articles and user.id is oldArticle.author
			)
		)
			throw 'Insufficient permissions'

		#
		# Construct Article
		#

		fields = clone query
		delete fields.data if not typeOf.Object fields.data

		if fields.data
			if typeOf.Object oldArticle.data
				fields.data = merge oldArticle.data, fields.data

		success = yield Model()
			.where { id: articleId }
			.update fields

		if success
			json.id			= articleId
			json.success	= true

		#
		# Construct Article Meta
		#

		# Always commit meta entries so to consistantly overwrite
		metaEntries = [
			A.handlers.models.parseCategoryIdInput query.categories
			yield A.handlers.models.parseAndCommitTagNameInput query.tags
		]

		entry.articleId	= articleId for entry in metaEntries

		json.metaIds = yield A.handlers.models.commitArticleMeta metaEntries
		yield return

	delete: (o) ->
		{ query, json, session } = o
		articleId = parseInt query.id

		json.success	= false
		json.id			= null

		if not articleId
			throw 'Invalid parameters; invalid article id'

		oldArticle = yield A.db.Articles()
			.where { id: articleId }
			.debug()
			.column 'articles.id'
			.selectOne { raw: true, private: true, disabled: true, page: undefined }

		if not oldArticle?.id
			throw 'Article by that id does not exist'

		articleId = oldArticle.id

		user = yield session.use()

		if not (
			user.role.can.delete.articles or (
				user.role.can.delete.owned.articles and user.id is oldArticle.author
			)
		)
			throw 'Insufficient permissions'

		metaResult = yield A.db.ArticlesMeta()
			.where { articleId }
			.limit 1
			.delete()

		articleResult = yield A.db.Articles()
			.where { id: articleId }
			.delete()

		json.id = articleId if articleResult

		json.articleDeleted		= articleResult
		json.articleMetaDeleted	= metaResult

		yield return


