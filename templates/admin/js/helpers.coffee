window.jQuery	=
window.$		= require 'jquery'
CodeMirror		= require 'codemirror'
marked			= require 'marked'

require 'jquery.date'
require 'autosize'
require 'selectize'

window.DEBUG = true
window.A = A = {}
window.delay = (callback, delay) -> setTimeout delay, callback

A.helpers = helpers = {}

#
# Events
#

A.events = {
	events: {}
	emit: (listeners, args...) ->
		if typeof listeners is 'string'
			listeners = [listeners]

		for name in listeners
			if '*' of @events
				for event in @events['*']
					result = event.callback name, event, args
					return false if result is false # do not proc any more listeners

			if name of @events
				indexesToRemove = []

				for event, index in @events[name]
					if event.limit <= 1
						indexesToRemove.push index

					if event.limit >= 1
						result = event.callback.apply null, args
						continue if result is false # do not proc any more listeners

				for index in indexesToRemove
					@events[name].splice index, 1

		return true

	on: (listeners, options, callback) ->
		if typeof listeners is 'string'
			listeners = [listeners]

		if not callback
			callback = options or ->
			options = {}

		for name in listeners
			event = {
				callback
				limit: options.limit or Infinity
			}

			if name not of @events
				@events[name] = []

			@events[name].push event

	one: (listeners, callback) ->
		@on listeners, { limit: 1 }, callback
}

#
# Requests
#

A.request = (options = {}, done = ->) ->
	{method, data, url} = options
	method or method = 'get'

	if not url
		return done new Error 'Invalid URL'

	if data and helpers.isIterable data
		for key, val of data
			if val and helpers.isIterable val
				data[key] = JSON.stringify val

	if DEBUG
		console.log '>> Req:', method, url, 'with', data
		startTime = new Date()

	$.ajax {
		method, url, data
		error: done
		success: (json) ->
			if DEBUG
				time = new Date().getTime() - startTime.getTime()
				console.log '[', time, 'ms ]', '<< Res:', json

			done null, json
	}

for method in ['get', 'post', 'put', 'delete']
	do (method) ->
		A.request[method] = (options, done) ->
			options.method = method
			return A.request options, done

#
# Tabs
#

A.tabs = ($findIn = $('body')) ->
	self = @tabs
	itemCount = 0

	if DEBUG
		startTime = new Date()

	$findIn.find('[data-tab]').each ->
		$button		= $(this)
		name		= $button.data 'tab'
		isActive	= !! $button.data('active')?

		if not scope = $button.data 'tabScope'
			if ( $parentScope = $button.parents('[data-tab-scope]').first() ).length
				scope = $parentScope.data 'tabScope'

		return null if not scope or not name

		if ( $byParentContent = $("[data-tab-scope='#{scope}'] [data-tab-content='#{name}']", $findIn).first() ).length
			$content = $byParentContent
		else
			$content = $("[data-tab-scope='#{scope}'][data-tab-content='#{name}']", $findIn)

		return null if not $content.length

		if scope not of self.tabs
			self.tabs[scope] = {}

		self.tabs[scope][name] = tab = {
			$button
			scope
			name
			$content
			active: isActive
		}

		tab.switch = (args) ->
			self.switch tab.scope, tab.name, args

		tab.emit = (phrase = '', args) ->
			phrase = ' ' + phrase if phrase
			A.events.emit "tabs:#{scope}#{phrase}", tab, args
			A.events.emit "tabs:#{scope}:#{name}#{phrase}", tab, args

		tab.on = (phrase = '', callback) ->
			phrase = ' ' + phrase if phrase
			A.events.on "tabs:#{scope}#{phrase}", callback
			A.events.on "tabs:#{scope}:#{name}#{phrase}", callback

		$button.unbind 'click.tabs'

		$button.on 'click.tabs', ->
			self.switch scope, name
			if href = $(this).attr 'href'
				if href[0] is '#'
					return true

			return false

		#if isActive and tab.$content.is(':visible')
		#	tab.emit 'activated'

		++itemCount

	if DEBUG
		time = new Date().getTime() - startTime.getTime()
		console.log '[', time, 'ms ]', 'A.tabs() mapped', itemCount, 'items'
		console.log @tabs.tabs.newArticle
A.tabs.tabs = {}

A.tabs.switch = (tabScope, tabName, args = null) ->
	return false if not tabScope or not tabName

	return false if not scopedTabs = @tabs[tabScope]

	scopedTab	= scopedTabs[tabName]

	return false if scopedTab.active

	for name, tab of scopedTabs
		continue if name is tabName

		if tab.active
			tab.active = false
			tab.$button.removeAttr 'data-active'
			tab.$content.removeAttr 'data-active'
			tab.emit 'deactivated', args

	scopedTab.active = true
	scopedTab.$button.attr 'data-active', ''
	scopedTab.$content.attr 'data-active', ''
	scopedTab.emit 'activated', args

	return false

#
# Popups
#
# popup = {
# 	name, active: Boolean
# 	$buttons: Array, $popup: jQuery
# 	toggle: Function, show: Function, hide: Function
# }
#

A.popups = ($findIn = $('body')) ->
	self = @popups
	itemCount = 0

	if DEBUG
		startTime = new Date()

	$('[data-popup]', $findIn).each ->
		$popup		= $(this)
		name		= $popup.data 'popup'

		return null if not name

		$buttons = $("[data-popup-button=#{name}]")

		isActive = !! $popup.data('active')?

		return null if not $popup.length

		popup = self.popups[name] = {
			name
			active: false
			$buttons
			$popup
			active: isActive
		}

		popup.$head = $popup.find '.popupHead'
		popup.$body = $popup.find '.popupBody'

		popup.toggle = () ->
			self.toggle name
			return this

		popup.show = () ->
			self.show name
			return this

		popup.hide = () ->
			self.hide name
			return this

		popup.populate = (head, body, options) ->
			self.populate name, head, body, options
			return this

		popup.timer = ($counter, ms, interval) ->
			self.timer name, $counter, ms, interval
			return this

		$buttons.popup	= 
		$popup.popup	= popup

		$buttonSet = $buttons.add( $('.popupClose', $popup) )
		$buttonSet.unbind 'click.popups'
		$buttonSet.on 'click.popups', (event) ->
			popup.toggle()
			$button = $(this)

			if !! $button.data('passLink')?
				event.preventDefault()

		$inner1 = $popup.find '> .popupInner1'

		$inner1.unbind 'click.popups'
		$inner1.on 'click.popups', (event) ->
			if $inner1.is(event.target) and $inner1.has( event.target ).length is 0
				popup.hide()

		++itemCount

	if DEBUG
		time = new Date().getTime() - startTime.getTime()
		console.log '[', time, 'ms ]', 'A.popups() mapped', itemCount, 'items'

	@isSetup = true

	return A.popups

A.popups.popups = {}

A.popups.toggle = (name, args = null) ->
	return this if not name or name not of @popups or not @isSetup

	popup = @popups[name]

	if popup.active
		return @hide name

	return this

A.popups.show = (name) ->
	if name and popup = @popups[name]
		popup.$popup.attr 'data-active', ''
		popup.active = true

	return this

A.popups.hide = (name) ->
	if name and popup = @popups[name]
		popup.$popup.removeAttr 'data-active'
		popup.active = false

	return this

A.popups.hideAll = ->
	for popupName of @popups
		@hide popupName

	return this

A.popups.populate = (name, head, body, options = {}) ->
	return this if not name

	if not popup = A.popups.popups[name]
		return this

	popup.$head?.html head if head?
	popup.$body?.html body if body?

	return this

A.popups.timer = (name, $counter, fullTime = 0, intervalTime = 1000)->
	return this if not name or not $counter

	counter = 0
	maxCounter = Math.round fullTime / intervalTime

	$counter.html maxCounter

	interval = setInterval ( ->
		$counter.html maxCounter - ( ++counter )
		if counter >= maxCounter
			clearInterval interval
			A.popups.hide name
	), intervalTime

	return this

A.popups.get = (name) ->
	return if name is null then A.popups.popups else A.popups.popups[name]

#
# Editables
#
A.editable = (options = {}) ->
	self = @editable
	{controls} = self

	$findIn = options.findIn or $('body')

	itemCount = 0

	if DEBUG
		startTime = new Date()

	# Sets up the controls markup + bindings
	controls()

	$findIn.find('textarea[data-editable], input[data-editable]').each ->
		$input	= $ this
		$form	= $input.closest 'form'

		scope	= $form.data('editable') or 'noscope'
		action	= $form.attr 'action'
		method	= $form.attr 'method'

		if $input.data('id')
			name = $input.data('id') + ':' + ( $input.data('name') or $input.attr('name') )
		else
			name = $input.data('name') or $input.attr('name')

		if not name
			return null

		if not self.items[scope]
			self.items[scope] = {}

		item = self.items[scope][name] = {
			$form
			parent: self.items[scope]
			scope
			$input
			name
			action
			method
			onSubmit	: (@submitCallback) ->
			onEdit		: (@editCallback) ->
			onDelete	: (@deleteCallback) ->
			onCancel	: (@cancelCallback) ->
		}

		# Extend item props with helper functions

		item.enable = ->
			self.enable scope, name
			controls.focused = true

		item.disable = ->
			self.disable scope, name
			controls.focused = false

		showControls = ->
			clearTimeout controls.timeout

			controls.bind item
				.position options.widthOffset or 0, options.heightOffset or 0
				.show()

		hideControls = ->
			clearTimeout controls.timeout

			controls.timeout = setTimeout ( ->
				if not controls.$controls.is(':hover') and not $input.is(':hover')
					controls.hide()
			), 500

		controls.$controls.on 'mouseleave', ->
			return null if controls.focused
			hideControls()

		$input.on 'keydown', (event) ->
			if event.keyCode is 27
				$input.blur()

		# check if disabled then if it isnt, make editable buttons etc
		$input.on 'mouseenter', ->
			return null if controls.focused
			showControls()

		$input.on 'mouseleave', (event) ->
			return null if controls.focused
			hideControls()
		
		$input.on 'focusin', ->
			controls.focused = true
			showControls()

		$input.on 'focusout', ->
			controls.focused = false
			if not controls.$controls.is(':hover')
				hideControls()
		
		++itemCount

	if DEBUG
		time = new Date().getTime() - startTime.getTime()
		console.log '[', time, 'ms ]', 'A.editable() mapped', itemCount, 'items'

	return self

A.editable.items = {}

A.editable.enable = (scope, name) ->
	if not item = @items[scope]?[name]
		return this

	item.$input
		.attr 'data-editing', ''
		.removeAttr 'readonly'
		.trigger 'autosize.resize'

	return this

A.editable.disable = (scope, name) ->
	if not item = @items[scope]?[name]
		return this

	item.$input
		.removeAttr 'data-editing'
		.attr 'readonly', ''
		.trigger 'autosize.resize'

	return this

#
# Editables Controls
# 
# Controls widget for editable items, contains buttons and whatnot
# This function sets it up

A.editable.controls = ->
	self = A.editable.controls

	if not $('.editableControls').length
		$('body').append """
			<div class="editableControls" data-hidden>
				<div data-button="edit">Edit</div>
				<div data-button="cancel">Cancel</div>
				<div data-button="submit">Save</div>
				<div data-button="delete">Delete</div>
				<div class="controlsStatus" data-state="" data-hidden></div>
			</div>
		"""

	self.$controls = $ '.editableControls'
	self.$status = self.$controls.find '.controlsStatus'
	self.buttons = buttons = {}

	for name in ['edit', 'cancel', 'submit', 'delete']
		buttons[name] = { $button: self.$controls.find "[data-button=#{name}]" }

	buttons.edit.clicked = ->
		{item} = self

		# item.editCallback # handle this shit
		item.initialContent = item.$input.val()
		item.enable()
		item.$input.focus()

		self.buttonVisibility()

	buttons.cancel.clicked = ->
		{item} = self

		item.$input.val item.initialContent
		item.disable()

		self.buttonVisibility()

	buttons.submit.clicked = ->
		{item} = self
		{action} = item

		data = {
			id: item.$input.data 'id'
		}
		
		fieldName		= item.$input.attr 'name'
		data[fieldName]	= item.$input.val()

		self.$status
			.removeAttr 'data-state'
			.removeAttr 'data-hidden'

		A.request {
			method: 'put'
			url: action
			data
		}, (err, json) ->
			success = true

			if err or not json or not json.success
				success = false

			self.$status
				.attr 'data-state', if success then 'success' else 'failure'
				.removeAttr 'data-hidden'

			item.disable()
			self.buttonVisibility()

			delay 1000, ->
				self.$status.attr 'data-hidden', ''

				if success
					self.hide()
				else
					item.enable()
					self.buttonVisibility()

	buttons.delete.clicked = ->
		{item} = self
		{action} = item

		data	= { id: item.$input.data 'id' }

		A.request {
			method: 'delete'
			url: action
			data
		}, ->

	return A.editable.controls

A.editable.controls.bind = (item) ->
	if item
		@item = item

	if not @item
		return this

	@buttonVisibility()

	for name, button of @buttons
		do (name, button) ->
			button.$button.unbind 'click.controls'
			button.$button.on 'click.controls', ->
				button.clicked.apply button, arguments

	# TODO: make a preference
	#item.$input.one 'dblclick', =>
	#	if not ( item.$input.data 'editing' )?
	#		@buttons.edit.clicked.apply @buttons.edit, arguments

	return this

A.editable.controls.buttonVisibility = (options = {}) ->
	isDisabled = !! ( @item.$input.attr 'readonly' )?
	isEditing = !! ( @item.$input.data 'editing' )?

	@buttons.cancel.$button.hide()
	@buttons.submit.$button.hide()

	if not isDisabled
		@buttons.edit.$button.hide()
		@buttons.cancel.$button.show()
		@buttons.submit.$button.show()

		if @item.deletable
			@buttons.delete.$button.show()
	else
		@buttons.edit.$button.show()
		@buttons.cancel.$button.hide()
		@buttons.submit.$button.hide()
		@buttons.delete.$button.hide()

	if @item.alwaysDeletable
		@buttons.delete.$button.show()

A.editable.controls.position = (widthOffset = 0, heightOffset = 0) ->
	if not @item
		return this

	width = @item.$input.outerWidth()
	height = @item.$input.outerHeight()

	tooltipHeight = @$controls.outerHeight()

	offset = @item.$input.offset()

	offset.left	= offset.left + width + widthOffset
	offset.top	= offset.top + ( height / 2 ) - ( tooltipHeight / 2 ) + heightOffset

	@$controls.css 'top', offset.top
	@$controls.css 'left', offset.left

	return this

A.editable.controls.show = ->
	@$controls.show()
	return this

A.editable.controls.hide = ->
	@$controls.removeAttr 'data-hidden'
	@$controls.hide()
	return this

#
# Revealer
#
# Takes a button with [data-show] or [data-hide], and when clicked
# hides or shows where the [data-show] or [data-hide] key matches [data-reveal] on another element

A.revealer = ($findIn = $('body')) ->
	self = @revealer
	itemCount = 0

	if DEBUG
		startTime = new Date()

	$('[data-show], [data-hide]', $findIn).each ->
		$button	= $(this)

		showSelector = $button.data 'show'
		hideSelector = $button.data 'hide'

		if showSelector
			$showTarget = $findIn.find showSelector
			$button.unbind 'click.revealer_show'
			$button.on 'click.revealer_show', ->
				$showTarget.show()

		if hideSelector?
			if hideSelector
				$hideTarget = $findIn.find hideSelector
			else
				$hideTarget = $button

			$button.unbind 'click.revealer_hide'
			$button.on 'click.revealer_hide', ->
				$hideTarget.hide()

		++itemCount

	if DEBUG
		time = new Date().getTime() - startTime.getTime()
		console.log '[', time, 'ms ]', 'A.revealer() mapped', itemCount, 'items'

#
# Markdown
#

A.markdown = ($findIn = $('body')) ->
	self = @markdown
	itemCount = 0

	if DEBUG
		startTime = new Date()

	$('[data-markdown]', $findIn).each ->
		$input		= $(this)
		name		= $input.data 'markdown'
		console.log name, $input
		return null if not name

		$scope = $input.closest '[data-markdown-scope]'

		if not $scope.length
			$scope = $findIn

		$output = $("[data-markdown-output='#{name}']", $scope)

		console.log 1

		return null if not $output.length

		input = CodeMirror.fromTextArea $input[0], { lineWrapping: true }
		self.items.push item = {
			name
			input
			$output
		}

		item.render = ->
			A.markdown.render input, $output
			input.save()
			return this

		item.render()

		input.on 'update', -> item.render()

		++itemCount

	if DEBUG
		time = new Date().getTime() - startTime.getTime()
		console.log '[', time, 'ms ]', 'A.markdown() mapped', itemCount, 'items'

A.markdown.render = (input, output) ->
	return if typeOf.String input
		output.html marked input
	else
		output.html marked input.getValue()

A.markdown.find = (key) ->
	for item in @items when key of item
		return item
	return null

A.markdown.items = []

marked.setOptions {
	gfm			: true
	tables		: true
	breaks		: true
	pedantic	: false
	sanitize	: true
	smartLists	: true
	smartypants	: true
}

A.codeMirror = ($findIn = $('body')) ->
	$findIn.find( '[data-code-mirror]' ).each ->
		input = CodeMirror.fromTextArea this, { lineWrapping: true }

		input.on 'update', -> input.save()

#
# Cloner
#
# Parses markup:
# 	<input data-clone="titleSlug" data-clone-selector="#pies" />
# 
# Where data-clone is a name, so it can be accessed later
#
# TODO: add clone-scope attribute to quaranteen this shit with markup!
#
A.cloner = ($findIn = $('body')) ->
	self = @cloner
	itemCount = 0

	if DEBUG
		startTime = new Date()

	$('[data-clone]', $findIn).each ->
		$input		= $(this)
		eventName	= $input.data 'event'

		$scope		= $input.closest '[data-clone-scope]'
		$scope		= $input.closest '[data-scope]' if not $scope.length
		
		scope		= $scope.data('cloneScope') or $scope.data('scope') or 'noscope'
		selector	= $input.data 'clone'

		$findIn = $scope if $scope.length

		$output = $findIn.find selector

		return null if not $output?.length

		item = {
			event: eventName
			selector
			scope
			$scope
			$input
			$output
			val		: $input.val()
			attr	: $input.data('cloneAttr') or 'html'
		}

		$input.unbind '.cloner'
		$input.on 'keyup.cloner', ->
			item.val = $input.val()
			self.clone item

		self.clone item

		++itemCount

	if DEBUG
		time = new Date().getTime() - startTime.getTime()
		console.log '[', time, 'ms ]', 'A.cloner() mapped', itemCount, 'items'

A.cloner.clone = (item) ->
	if item.event
		A.events.emit "cloner:#{item.event}", item

	if item.preoperation
		item.preoperation => @actuallyClone item
	else
		@actuallyClone item

A.cloner.actuallyClone = (item) ->
	val = if not item.val? then item.$input.val() else item.val

	switch item.attr or 'html'
		when 'html'
			item.$output.each -> $(this).html val
		when 'val', 'value'
			item.$output.val val
		else
			item.$output.attr attr, val

#
# Switch
#

A.switch = ($findIn = $('body')) ->
	self = @.switch
	itemCount = 0

	if DEBUG
		startTime = new Date()

	$('[data-switch]', $findIn).each ->
		type = 'button'

		$switch		= $(this)
		eventName	= $switch.data 'event'

		$scope		= $switch.closest '[data-switch-scope]'
		$scope		= $switch.closest '[data-scope]' if not $scope.length
		
		scope		= $scope.data('switchScope') or $scope.data('scope') or 'noscope'
		selector	= $switch.data 'switch'

		$findIn = $scope if $scope.length

		$target = $findIn.find selector

		return null if not $target?.length

		item = {
			event: eventName
			selector
			scope
			$scope
			$switch
			$target
		}

		$switch.unbind '.switch'
		$switch.on 'click.switch', ->
			self.toggle item

		++itemCount

	if DEBUG
		time = new Date().getTime() - startTime.getTime()
		console.log '[', time, 'ms ]', 'A.buttonSwitch() mapped', itemCount, 'items'

A.switch.toggle = (item) ->
	if item.$switch.attr('data-active')?
		item.$switch.removeAttr 'data-active'
	else
		item.$switch.attr 'data-active', ''

	switched = helpers.numberToBoolean item.$target.val()
	item.$target.val helpers.booleanToNumber ! switched

#
# Touchables
#
# Simply changes an attribute once when certian events fire for it
#
A.touchable = ($findIn = $('body')) ->
	self = @touch
	itemCount = 0

	if DEBUG
		startTime = new Date()

	$('[data-touchable]', $findIn).each ->
		$item = $(this)

		if not $item.data('touched')?
			$item.one 'keyup, focus, click', ->
				$item.attr 'data-touched', ''

		++itemCount

	if DEBUG
		time = new Date().getTime() - startTime.getTime()
		console.log '[', time, 'ms ]', 'A.touch() mapped', itemCount, 'items'

#
# Selectize
#

A.selectize = ($findIn = $('body')) ->
	plugins = [
		'remove_button'
		'restore_on_backspace'
	]

	if ( $element = $findIn.find '[data-selectize]' ).length
		$element.selectize {
			plugins
		}

	if ( $element = $findIn.find '[data-selectize-list]' ).length
		$element.selectize {
			plugins
			create: (input) -> {
				value: input
				text: input
			}

		}

#
# Textarea Autosize
#

A.textareaAutosize = ($findIn) ->
	$findIn.find('textarea')?.autosize?()

#
# Misc utilities/helpers
#

helpers.tableButtonOptions = ($button, $form) ->
	$form = $button.closest 'form' if not $form

	return {
		method: ( $button.attr 'formmethod' ) or ( $form.attr 'method' ) or 'POST'
		url: ( $button.attr 'formaction' ) or ( $form.attr 'action' ) or ''
		data: { id: $button.data('id') or $button.closest('tr').data 'id' }
	}

helpers.numberToBoolean = (number) -> if ( parseInt number ) >= 1 then true else false
helpers.booleanToNumber = (boolean) -> if boolean is true then 1 else 0

helpers.removeTableRow = ($tr) ->
	# todo: do some delay and class stuff to make it obvious
	$tr.remove()

helpers.setUrl = (url = '') ->
	history.pushState '/', '/', url

helpers.parseHashbang = (url) ->
	url			= window.location.href if not url
	hashTags	= ( url.split '#!' )[1]?.split('/')
	result		= { _tags: hashTags }

	if length = hashTags?.length
		position = result

		for tag, index in hashTags
			position = position[tag] =
			position._child = { _index: index, _value: tag }

	return result

helpers.parseGET = (url = '') ->
	obj = {}

	query = url.split('?')[1]

	if query?
		for val in query.split '&'
			parts = val.split '='
			obj[ parts[0] ] = decodeURIComponent parts[1].replace /\+/g, ' '

	return obj

helpers.addGET = (url, getVars) ->
	newUrl = url.split('?')[0] + '?'

	queryParts = []
	for key, val of getVars
		queryParts.push key + '=' + encodeURIComponent val.replace /\+/g, ' '
		
	newUrl += queryParts.join '&'

	return newUrl

helpers.isIterable = (vari) ->
	return ( vari isnt null and typeof vari is 'object' ) or typeof vari is 'array'

helpers.slugify = (str = '') ->
	str = decodeURIComponent str.toString('utf8')

	return str
		.toLowerCase()
		.replace( /[^a-z0-9-]+/g, '-' )
		.replace( /^[\s\-]+|[\s\-]+$/g, '' )

helpers.camelCase = (str = '') ->
	return ( helpers.slugify str )
		.replace /([ -]+)([a-zA-Z0-9])/g, (a, b, c) -> c.toUpperCase()
		.replace /([0-9]+)([a-zA-Z])/g, (a, b, c) -> c.toUpperCase()
		.replace /([0-9]+)([a-zA-Z])/g, (a, b, c) -> b + c.toUpperCase()

merge			=
helpers.merge	= (obj1, obj2, depth = 4) ->
	if depth > 0
		for own key of obj2
			obj2Type = helpers.typeOf obj2[key]
			obj1Type = helpers.typeOf obj1[key]
			if (
				( obj2Type is 'function' or obj2Type is 'object' ) and
				key of obj1 and
				( obj1Type is 'function' or obj1Type is 'object' )
			)
				arguments.callee obj1[key], obj2[key], depth - 1
			else
				obj1[key] = obj2[key]

	return obj1

typeOf			=
helpers.typeOf = (vari) ->
	return switch Object::toString.call vari
		when '[object Undefined]'	then 'undefined'
		when '[object String]'		then 'string'
		when '[object Function]'	then 'function'
		when '[object Boolean]'		then 'boolean'
		when '[object Object]'		then 'object'
		when '[object Array]'		then 'array'
		when '[object Null]'		then 'null'
		when '[object Number]'		then ( if vari then 'number' else 'nan' )
		when '[object Date]'		then 'date'
		when '[object RegExp]'		then 'regexp'
		else 'null'

fullTypeTable = {
	'Undefined'	: undefined
	'Boolean'	: Boolean
	'String'	: String
	'Function'	: Function
	'Array'		: Array
	'Object'	: Object
	'Null'		: null
	'Number'	: Number
	'Date'		: Date
	'RegExp'	: RegExp
	'NaN'		: NaN
}

for key of fullTypeTable
	do (key) ->
		key2		= key.toLowerCase()
		typeOf[key]	= (vari) -> typeOf( vari ) is key2


#
# jQuery extensions
#

$.event.special.remove = {
	remove: (o) ->
		if o.handler
			o.handler()
}

jQuery.fn.mouseIsOver = ->
	return $(this).parent().find($(this).selector + ":hover").length > 0

jQuery.fn.flexInput = ->
	$input = $(this)

	$input.flexInput.remove = ->
		$input.unbind 'keydown.flexInput'
		$input.unbind 'keyup.flexInput'
		$flexer.remove()

	$input.flexInput.$flexer = $flexer = $('<editbox contenteditable="true"></editbox>')
	$flexer.css {
		position		: 'absolute'
		top				: -9999
		left			: -9999
		width			: 'auto'
		fontSize		: $input.css('fontSize')
		fontFamily		: $input.css('fontFamily')
		fontWeight		: $input.css('fontWeight')
		letterSpacing	: $input.css('letterSpacing')
		whiteSpace		: 'nowrap'
	}

	$('body').prepend $flexer

	flex = (add = 2) ->
		escapedVal = $input.val().replace /[ ]/g, '&nbsp;'
		$flexer.html escapedVal
		$input.width $flexer.width() + add

		return true

	flex()

	$input.on 'keydown.flexInput', -> flex 8
	$input.on 'keyup.flexInput', -> flex 8

	$input.on 'remove', ->
		$input.flexInput.remove()

	return $input