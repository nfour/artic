A = require '../../app'


module.exports = class Text extends A.modules.models.Store_ObjectData
	key			: 'text'
	valueKey	: 'value'
	defaults	: A.data.defaults.stores.text

	# todo: not-critical, add validation with create, update functions
