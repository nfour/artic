A = require '../../app'

module.exports = class Routes extends A.modules.models.Store_ArrayData
	key			: 'routes'
	defaults	: A.data.defaults.stores.routes

	
	# todo: add validation with create, update functions
