A		= require '../app'
Promise	= require 'bluebird'

{ merge, clone } = A.utils

module.exports = class Tags extends A.modules.models.Model
	tableName: 'tags'
	
	validation:
		name	: true
		slug	: true
		text	: null


	define: (table) ->
		table.increments	'id'
			.primary()


		table.string		'name',		255
		table.string		'slug',		255
			.index()

		table.text			'text',		'mediumtext'

		return table
