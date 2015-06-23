A		= require '../app'
Base	= require '../modules/models/Model'

{ merge, clone } = A.utils

module.exports = class UsersMeta extends Base
	tableName: 'usersMeta'
	
	validation:
		userId	: true
		key		: true
		text	: null
		string	: null
		integer	: null
		boolean	: null
		
	define: (table) ->
		table.increments	'id'
			.primary()
			
		table.bigInteger	'userId'
			.defaultTo(0)
			.index()

		table.string		'key',		32
			.index()

		table.text			'text',		'mediumtext'
		table.string		'string',	255
		table.bigInteger	'integer'
		table.boolean		'boolean'
			.index()

		return table
