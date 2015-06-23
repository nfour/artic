A = require '../app'

{ merge, clone } = A.utils

module.exports = ->
	A.lance.on 'serveTemplate', (o) ->
		data = merge.black o.template.data, A.locals

		mergeData	= {}
		keys		= [ 'settings', 'text' ]

		#if data.article
		#	keys.push 'article'

		#mergeData[ key ] = data[ key ] for key in keys
			
		#A.helpers.interpolate.all data, mergeData

		# todo: to make this work, iterate over all the articles and individually choose which fields will be interpolated

		#if data.articles
		#	for article in data.articles
		#		mergeData.article = article
		#		A.helpers.interpolate.all article, mergeData

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
