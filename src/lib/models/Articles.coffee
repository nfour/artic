A		= require '../app'
Promise	= require 'bluebird'

{ merge, clone, typeOf } = A.utils

module.exports = class Articles extends A.modules.models.Model
	tableName: 'articles'
	
	validation:
		createdAt	: true
		updatedAt	: true
		publishedAt	: true
		title		: true
		slug		: true
		blocks		: true
		blocksMd	: true
		
		author: (author, fields) ->
			if not user = yield @db.Users().where({ id: author }).selectOne()
				throw 'Invalid author'

			yield return user.id
			
		data		: true
		disabled	: null
		private		: null
		published	: null
		page		: null

	# Used to determine when to cast as a bool
	booleanFields:
		disabled	: true
		private		: true
		published	: true
		page		: true
		
	constructor: ->
		super

		merge @o,
			raw				: false,	meta		: true
			private			: false,	disabled	: false
			unpublished		: true,		page		: false

			greedyCategories: false,	greedyTags	: false
			resolveTags		: true
			tags			: [],		categories	: []

	categories: (needles) ->
		needles = [ needles ] if not typeOf.Array needles

		for needle in needles when needle
			if typeOf.Number needle
				@o.categories.push needle
			else if category = A.db.stores.categories.findOne needle
				@o.categories.push category.id

		return this

	###
		Adds tag id's to the paramaters for a select query, which will be used in a `where` statement.
		If any single tag id is found, the select will succeed, and only if the `greedyTags` option is false (default: false).

		@param tagIds {Array} An array of tag ids and if not an array, accepts `arguments` instead. Number or String
		@return {this}
	###
	tags: (tagIds) ->
		tagIds = [ tagIds ] if not typeOf.Array tagIds
		tagIds = ( val for val in tagIds when val = parseInt val )

		if tagIds.length
			@o.tags = @o.tags.concat tagIds

		return this

	###
		Select articles and article meta. Reads data specified from sibling functions: categories, tags

		@param options {Object}
		@option options private {Boolean} (default: false) Whether `private` articles may be selected
		@option options disabled {Boolean} (default: false) Whether `disabled` articles may be selected
		@option options greedyTags {Boolean} (default: false) When true require all to be attatched to an article else only one
		@option options greedyCategories {Boolean} (default: false) When true require all to be attatched to an article else only one
		@option options meta {Boolean} (default: true) Whether to select meta from ArticlesMeta for each article
		@option options resolveTags {Boolean} (default: false) (Requires meta to be true) Whether to resolve tagIds to rows in the `tags` table
		@option options raw {Boolean} (default: false) Whether to select only untouched database rows

		@return {Promise, Array} An array of articles
	###
	select: (o) ->
		merge @o, o if o
		o = @o
		
		{ raw, rawEscape } = this
		{ tags, categories } = o

		#
		# Advanced Taxonomy filtering
		#

		if tags?.length
			@join 'articlesMeta as tags', ->
				@on	'articles.id'	, '=', 'tags.articleId'
				@on	'tags.key'		, '=', rawEscape 't'

				#@on ->

				# todo: test new knex functionality
				# Jump through hoops because knex is stupid
				onModifier	= if o.greedyTags then @on.bind this else @orOn.bind this
				length		= tags.length

				if length is 1
					@on raw(''), '', raw "FIND_IN_SET('#{ tags[0] }', tags.string)"
				else
					for id, index in tags
						# We use this switch to surround the statement in parenthesis
						switch
							when index is 0
								@on raw('('), '', raw "FIND_IN_SET('#{ id }', tags.string)"
							when ( index + 1 ) is length
								onModifier raw(''), '', raw "FIND_IN_SET('#{ id }', tags.string) )"
							else
								onModifier raw(''), '', raw "FIND_IN_SET('#{ id }', tags.string)"

		if categories?.length
			@join 'articlesMeta as categories', ->
				@on	'articles.id'		, '=', 'categories.articleId'
				@on	'categories.key'	, '=', rawEscape 'c'

				# Jump through hoops because knex is stupid
				onModifier	= if o.greedyCategories then @on.bind this else @orOn.bind this
				length		= categories.length

				if length is 1
					@on raw(''), '', raw "FIND_IN_SET('#{ categories[0] }', categories.string)"
				else
					for id, index in categories
						# We use this switch to surround the statement in parenthesis
						switch
							when index is 0
								@on raw('('), '', raw "FIND_IN_SET('#{ id }', categories.string)"
							when ( index + 1 ) is length
								onModifier raw(''), '', raw "FIND_IN_SET('#{ id }', categories.string) )"
							else
								onModifier raw(''), '', raw "FIND_IN_SET('#{ id }', categories.string)"

		#
		# Switches
		#

		if false in [ o.private, o.disabled, o.page ]
			@andWhere ->
				@andWhere { 'articles.private'	: false } if not o.private
				@andWhere { 'articles.disabled'	: false } if not o.disabled
				@andWhere { 'articles.page'		: false } if not o.page

		# If unpublished is true, get all articles including unpublished/drafts
		if not o.unpublished
			@andWhere { 'articles.published': true }

		if o.page
			@andWhere { 'articles.page': true }

		return yield super

	insert: (rows) ->
		rows ?= @o.fields
		rows = [ rows ] if not typeOf.Array rows

		for fields, index in rows
			# Validation
			if not fields.title
				throw 'Invalid article title'

			# Formatting
			if not fields.createdAt
				fields.createdAt =
				fields.updatedAt = new Date().getTime()

			if not fields.publishedAt
				fields.publishedAt = fields.createdAt

		return yield super rows

	update: (fields) ->
		fields ?= @o.fields

		if not fields.updatedAt
			fields.updatedAt = new Date().getTime()

		return yield super fields

	formatInput: (rows) ->
		for fields in rows
			# Format
			fields.slug = fields.slug or A.utils.format.slugify fields.title

			fields.blocks	= [ fields.blocks ] if not typeOf.Array fields.blocks
			fields.blocksMd	= [ fields.blocksMd ] if not typeOf.Array fields.blocksMd

			fields.data			= {} if not typeOf.Object fields.data
			fields.data.blocks	= [] if not typeOf.Array fields.data.blocks

			{ inspect } = A.utils

			for meta, index in fields.data.blocks
				meta		= meta or {}
				meta.key	= meta?.key or index
				meta.index	= parseInt meta.index or index
			
			# Converts the boolean fields to booleans
			for key of @booleanFields when key of fields
				val = fields[ key ]
				fields[ key ] = parseInt( val ) > 0 if not typeOf.Boolean val

		return yield super rows

	###
		Builds an article's properties from raw values by extending the object
		with resolved tags, resolved articleMeta, adding useful groupings and default properties.
		Attempts to be minimal to a point to minimize performance impacts.

		@param article {Object or Array}
		@return {Promise, Object} article ( Original input )
	###
	formatOutput: (articles) ->
		return articles if @o.raw

		items = if not typeOf.Array articles then [ articles ] else articles
	
		await = []

		# todo: make async with do -> and a new Promise
		for article in items then do (article) =>
			await.push do Promise.coroutine =>
				# Set defaults
				article.categoryIds			= []
				article.categories			= []
				article.categoriesById		= {}
				article.categoriesBySlug	= {}

				article.tagIds		= []
				article.tags		= []
				article.tagsById	= {}
				article.tagsBySlug	= {}

				# Parse data json

				article.data		= JSON.parse article.data if article.data
				article.blocks		= JSON.parse article.blocks if article.blocks
				article.blocksMd	= JSON.parse article.blocksMd if article.blocksMd

				# Resolve metadata
				if @o.meta
					yield A.handlers.models.extendArticleWithMeta article

					if article.categoryIds.length
						if data = A.handlers.models.findCategoriesById article.categoryIds
							article.categories = data

					if article.tagIds.length
						if data = yield A.handlers.models.findTagsById article.tagIds
							article.tags = data

					#
					# Format fields
					#

					if article.categories?.length
						groups = A.handlers.models.groupTerms article.categories

						article.categoriesById		= groups.byId
						article.categoriesBySlug	= groups.bySlug

					if article.tags?.length
						groups = A.handlers.models.groupTerms article.tags

						article.tagsById	= groups.byId
						article.tagsBySlug	= groups.bySlug

				article.block = (key) ->
					return article.block.find key, article.blocks

				article.block.find = (key, within) ->
					if typeOf.Number key
						return within[ key ] or ''
					else
						for item in article.data.blocks when item.key is key
							return within[ item.index ] or ''

						return ''

				article.block.markdown = (key) ->
					return article.block.find key, article.blocksMd

				article.block.meta = (key) ->
					return article.block.find key, article.data.blocks


				article.author = yield @db.Users().where({ id: article.author }).selectOne()

				yield return

		yield Promise.all await

		return articles

	define: (table) ->
		table.increments 'id'
			.primary()
			
		table.bigInteger 'createdAt'
			.notNullable()
			.defaultTo 0

		table.bigInteger 'updatedAt'
			.notNullable()
			.defaultTo 0

		table.bigInteger 'publishedAt'
			.notNullable()
			.defaultTo 0

		table.integer 'author'
		table.string 'title', 255

		table.string 'slug', 255
			.index()

		table.text 'blocks', 'mediumtext'
		table.text 'blocksMd', 'mediumtext'

		# json
		table.text 'data', 'mediumtext'

		# if not published, it's a draft
		table.boolean 'published', 0
			.notNullable()
			.defaultTo false
			.index()

		# when true, article is only visible to appropraite users
		table.boolean 'private', 0
			.notNullable()
			.defaultTo false
			.index()
		
		# when true, article is not visible publicly 
		table.boolean 'disabled', 0
			.notNullable()
			.defaultTo false
			.index()

		table.boolean 'page', 0
			.notNullable()
			.defaultTo false
			.index()

		return table
