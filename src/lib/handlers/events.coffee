A = require '../app'

{ merge, clone } = A.utils

module.exports = ->
	#
	# Decorations
	#

	A.on 'init', -> console.log '~ Initialising...'.grey

	A.db.on 'resetStores', ->
		console.log "!!".red + " Database resetStores activated" + " ( Cancel with ^+C )".grey

	A.db.on 'resetStores.interval', (remainingSeconds) ->
		console.log "!! STORES BEING RESET".red + " in... ".grey + "#{remainingSeconds}".yellow.bold

	A.db.on 'resetSchema', ->
		console.log "!!".red + " Database resetSchema activated" + " ( Cancel with ^+C )".grey

	A.db.on 'resetSchema.interval', (remainingSeconds) ->
		console.log "!! DATABASE TABLES BEING DROPPED".red + " in... ".grey + "#{remainingSeconds}".yellow.bold

	A.db.on 'table.created', (tableName) ->
		console.log '~ database table'.grey, 'created'.green + ':'.grey, tableName
		
	A.db.on 'table.dropped', (tableName) ->
		console.log '~ database table'.grey, 'dropped'.red + ':'.grey, tableName

	A.db.on 'store.reset', (store) ->
		console.log '~ database store'.grey, 'reset'.yellow + ':'.grey, store?.key

	A.db.on 'store.loaded', (store) ->
		console.log '~ database store'.grey, 'loaded'.green + ':'.grey, store?.key
		
	A.db.on 'ready', (cfg) ->
		console.log '~ database'.grey, 'ready'.green
