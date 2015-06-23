crypto = require 'crypto'

{ merge, clone } = require 'lutils'

###
	A class to help encryption of things like passwords and other user data
###
module.exports = class Crypto
	constructor: (cfg) ->
		@cfg =
			hashAlgorithm	: 'sha1'
			cipherAlgorithm	: 'aes192'

		merge @cfg, cfg if cfg

	encrypt: (str, length = 32) ->
		salt = @random length
		hash = @hash str, salt

		return [ hash, salt ]

	validateHash: (hash, salt, str) ->
		return hash is @hash str, salt

	random: (length) ->
		return crypto
			.randomBytes length
			.toString 'hex'

	hash: (str, salt = '') ->
		return crypto
			.createHash @cfg.hashAlgorithm
			.update str + salt
			.digest 'hex'

	cipher: (str, secret) ->
		cipher = crypto.createCipher @cfg.cipherAlgorithm, secret
		return ( cipher.update str, 'utf8', 'hex' ) + cipher.final 'hex'

	decipher: (str, secret) ->
		decipher = crypto.createDecipher @cfg.cipherAlgorithm, secret
		return ( decipher.update str, 'hex', 'utf8' ) + decipher.final 'utf8'
