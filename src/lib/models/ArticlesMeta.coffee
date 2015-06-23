A		= require '../app'
Promise	= require 'bluebird'

{ merge, clone } = A.utils

module.exports = class ArticlesMeta extends A.modules.models.Model
	tableName: 'articlesMeta'
	
	validation:
		articleId	: true
		key			: true
		text		: null
		string		: null
		integer		: null
		boolean		: null

	
	define: (table) ->
		table.increments	'id'
			.primary()
			
		table.bigInteger	'articleId'
			.defaultTo(0)
			.index()

		table.string		'key'		, 32
			.index()

		table.text			'text'		, 'mediumtext'
		table.string		'string'	, 255
		table.bigInteger	'integer'	
		table.boolean		'boolean'
			.index()

		return table
