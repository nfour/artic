A		= require '../app'
Promise	= require 'bluebird'

{ merge, clone } = A.utils

module.exports = class TagsMeta extends A.modules.models.Model
	tableName: 'tagsMeta'
	
	validation:
		tagId	: true
		key		: true
		text	: null
		string	: null
		integer	: null
		boolean	: null
		
	define: (table) ->
		table.increments	'id'
			.primary()
			
		table.bigInteger	'tagId'
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

