A = require '../../app'

module.exports = class Settings extends A.modules.models.Store_ObjectData
	key			: 'settings'
	valueKey	: 'value'
	defaults	: A.data.defaults.stores.settings
