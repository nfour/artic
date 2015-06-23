A		= require '../app'
Promise	= require 'bluebird'

{ merge, clone, typeOf } = A.utils

module.exports = class Stores extends A.modules.models.Model
	tableName: 'stores'
	
	validation:
		key			: true
		value		: null
	
	set: (key, value) ->
		if not typeOf.String value
			value = JSON.stringify value

		fields = yield @db.Stores()
			.where { key }
			.columns 'id'
			.selectOne()

		if fields?.id
			return yield @db.Stores()
				.where { id: fields.id }
				.update { value }
		else
			return yield @db.Stores()
				.insert { key, value }

	define: (table) ->
		table.increments 'id'
			.primary()
			
		table.string 'key', 128
			.index()

		table.text 'value', 'longtext'
		
		return table
