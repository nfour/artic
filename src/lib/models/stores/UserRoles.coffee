A = require '../../app'

{ merge, clone, typeOf } = A.utils

module.exports = class UserRoles extends A.modules.models.Store_ArrayData
	key			: 'userRoles'
	defaults	: A.data.defaults.stores.userRoles

	formatOutput: (rows) ->
		if rows then for role, index in rows
			rows[ index ] = role = clone role
			role.can = @buildPermissions role.can

		return rows

	buildPermissions: (perms) ->
		basePerms = clone @data[0].can, 20

		A.utils.format.setToFalse basePerms

		return merge.white basePerms, perms
