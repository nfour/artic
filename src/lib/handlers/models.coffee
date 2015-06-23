A		= require '../app'
Promise	= require 'bluebird'

{ sort, typeOf, merge, slugify, numberToBoolean } = A.utils
# TODO: numberToBoolean, slugify, add thse to utils, copy from lance

#
# Articles and ArticleMeta
#

###
	Inserts or updates meta entries to the database
	
	@param entries {Array} { articleId, key, ... }
	@option entries articleId	{Integer}	Required
	@option entries key			{String}	Required

	@return {Promise, Array} An array of inserted/updated ids [ 80, 4, ... ]
###
exports.commitArticleMeta = (entries) ->
	ids = []

	for entry in entries
		continue if not articleId = entry.articleId

		oldMeta = yield A.db.ArticlesMeta()
			.where { articleId, key: entry.key }
			.selectOne()

		# If meta exists then update by overwriting, else create a new entry
		# Captures all inserted/updated ids
		if oldMeta?.id
			yield A.db.ArticlesMeta()
			.where { id: oldMeta.id }
			.update entry

			ids = ids.concat oldMeta.id
		else
			if insertIds = yield A.db.ArticlesMeta().insert entry
				ids = ids.concat insertIds

	yield return ids

###
	Extends an article object with any matching meta entries from ArticlesMeta
	and parses them

	@param article {Object}
	@return {Promise, Object} article
###
exports.extendArticleWithMeta = (article) ->
	articleId = article.id

	rows = yield A.db.ArticlesMeta()
		.where { articleId }
		.select()

	article.meta = []

	if rows?.length then for fields in rows
		switch
			# Category ids
			when fields.key is 'c'
				article.categoryIds = article.categoryIds or []

				items = fields.string?.toString().split ','

				for val, index in items when val = parseInt val
					article.categoryIds.push val if val not in article.categoryIds

			# Tag ids
			when fields.key is 't'
				article.tagIds = article.tagIds or []

				items = fields.string?.toString().split ','

				for val, index in items when val = parseInt val
					article.tagIds.push val if val not in article.tagIds


	article.meta = rows or []

	yield return article

#
# Categories
#

###
	Takes an array of terms (tags or categories) and returns an object of variant sortings

	@param categories {Array} [ { id, slug, ... } ]
	@return {Object} { bySlug, byId }
###
exports.groupTerms = (terms) ->
	bySlug	= {}
	byId	= {}

	for term in terms when term
		bySlug[ term.slug ]	= term
		byId[ term.id ]		= term

	return { bySlug, byId }

###
	Creates a new array of categories sorted according to the order key

	@param categories {Array}
	@return {Array} A new array
###
exports.orderCategories = (categories) ->
	return sort categories, { key: 'order', order: 'asc' }

###
	Resolves category ids to category objects

	@param ids {Array} An array of id's
	@return {Array} An array of category objects [ {}, ... ]
###
exports.findCategoriesById = (ids) ->
	return ( category for id in ids when category = A.db.stores.categories.readOne { id } )

###
	Parse category id input then with a full list of *resolved* legit
	ids; generate an ArticleMeta entry (Though missing an articleId property)

	@param input {String or Array} Collection of category ids
	@return {Promise, Object} { key, string }
###
exports.parseCategoryIdInput = (input) ->
	defaultEntry = { key: 'c', string: '' }

	return defaultEntry if not input

	input		= [ input ] if not typeOf.Array input
	categoryIds = []

	for id in input when category = A.db.stores.categories.findOne { id }
		categoryIds.push category.id

	return defaultEntry if not categoryIds.length

	return {
		key		: 'c'
		string	: categoryIds.join ',' # 1,2,3,10,5
	}

###
	Parse tag input, commit missing tags to the database
	then with a full list of ids; generate an ArticleMeta entry
	(Though missing an articleId property)

	@param input {String or Array} Collection of tag names
	@return {Promise, Object} { key, string }
###
exports.parseAndCommitTagNameInput = (input) ->
	defaultEntry = { key: 't', string: '' }

	return defaultEntry if not input

	tagNames = if typeOf.Array input then input else [input]

	return defaultEntry if not tagNames.length

	primitives	= ( { name, slug: slugify name } for name in tagNames )

	wheres = ( { slug: item.slug } for item in primitives )

	tags = yield exports.findTags wheres

	newTags = []

	for item in primitives
		found = false
		if tags then for tag in tags when tag.slug is item.slug
			found = true
			break

		if not found
			newTags.push item

	tagIds = if tags
		( tag.id for tag in tags )
	else
		[]

	if newTags.length
		if insertedIds = yield A.db.Tags().insert newTags
			console.log 'added ', insertedIds, 'tags. all:', tagIds
			tagIds = tagIds.concat insertedIds

	yield return {
		key		: 't'
		string	: tagIds.join ','
	}

#
# Tags
#


### Resolves tag ids to tags from the database. Helper for exports.models.findTags().

	@param ids {Array} An array of id's corresponding to the id field in table `tags`
	@return {Array} An array of database rows [ {}, ]
###
exports.findTagsById = (ids) ->
	return null if not ids.length

	wheres = ( { id } for id in ids when id = parseInt id )

	return yield exports.findTags wheres

### Resolves tags from the database

	@param wheres {Array} An array of where to be chained eg. "WHERE 1 OR 2 OR 3"
	@return {Array} An array of database rows [ {}, ]
###
exports.findTags = (wheres) ->
	return null if not wheres?.length

	query = A.db.Tags()

	for where in wheres
		query.orWhere where
	
	return yield query.select()
