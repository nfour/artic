A			= require './app'
{ utils }	= require 'lance'

{ typeOf, merge, clone } = utils

module.exports = exports = utils.clone utils

#
# Formatting
#

###
	Santizies a username by removing non-whitelisted characters
	
	@param username {String}
	@return {String} username
###
exports.format.sanitizeUsername = (username = '') ->
	return username.replace /[^\w\-\_\.]/i, ''

###
	Very basic regex to determine if a string is email-ish (has an @ and is surrounded by not whitespace).

	@param email {String}
	@return {Boolean}
###
exports.format.validateEmail = (email) -> return /\S+@\S+\.\S/.test email or ''

###
	Capitalizes first characters of each word.

	@param str {String}
	@return {String} str
###
exports.format.capitalizeWords = (str) ->
	words = str.split ' '

	for word, index in words
		words[index] = word[0].toUpperCase() + ( word[1..] or '' )

	return words.join ' '

###
	Loop over all properties, deleting keys. If a value is an Object or Array
	then recur over it, thus preserving an objects structure and references.
	
	Warning: No circular loop protection beyond depth
	
	@param obj {Object, Array} A Object or Array
	@param depth {Number} Optional. Max depth to recur into.
	@return {mixed} obj
###
exports.format.skeletonize = (obj, depth = 3) ->
	return obj if depth < 1

	for key, val of obj
		switch typeOf val
			when 'array', 'object'
				arguments.callee val, --depth
			else
				delete obj[key]

	return obj

###
	Sets all values to false in an object recursively
###
exports.format.setToFalse = (obj) ->
	for key, val of obj
		if typeOf.Object val
			arguments.callee val
		else
			obj[ key ] = false

	return obj