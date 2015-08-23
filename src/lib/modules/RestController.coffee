###
	RestController.
	Handles REST/CRUD requests by matching the requests
	method with the corresponding CRUD method.
	
	Extend this to add `create`, `update`, `delete` and `read` methods.
	
	@version 0.1.0
###

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