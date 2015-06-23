A = require '../../app'

{ merge, clone, typeOf } = A.utils

module.exports = class Categories extends A.modules.models.Store_ObjectData
	key			: 'categories'
	defaults	: A.data.defaults.stores.categories
	
	create: (fields = {}) ->
		fields = {
			name	: fields.name or ''
			slug	: fields.slug or ''
			order	: parseInt( fields.order ) or 0
			count	: parseInt( fields.count ) or 0
			parent	: parseInt( fields.parent ) or 0
		}
	
		return false if not fields.name

		fields.slug or fields.slug = A.utils.format.slugify fields.name

		# Check to see if an existing slug is in use
		existingIds = []
		for id, category of @data
			if category.slug.toLowerCase() is fields.slug.toLowerCase()
				return false

			existingIds.push category.id

		fields.id = 1
		fields.id++ while fields.id in existingIds

		return super fields.id, fields
