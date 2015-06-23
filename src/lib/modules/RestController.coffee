module.exports = class RestController
	crudMap:
		GET	: 'read',	POST	: 'create'
		PUT	: 'update',	DELETE	: 'delete'

	crud: (o) =>
		key = @crudMap[ o.method.toUpperCase() ]

		if not @[ key ]?
			throw 'Invalid REST method'

		return yield @[ key ] o
	
	require('coroutiner') @prototype