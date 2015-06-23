require './helpers'

pageReadyTime = new Date()

{typeOf, merge, setUrl} = A.helpers


$(document).ready ->
	if DEBUG
		time = new Date().getTime() - pageReadyTime.getTime()
		console.log '[', time, 'ms ]', '$(document).ready'

		A.events.on '*', (eventName, event, args) ->
			console.log '!event!', eventName

	URL			= window.location.href
	BASE_URL	= window.location.protocol + '//' + window.location.host + window.location.pathname
	GET			= A.helpers.parseGET URL
	HASHBANG	= A.helpers.parseHashbang URL

	#
	# Events ( Order is important )
	#

	# Map tab keys to api keys for calling api
	# Some tabs are excluded as they do it differently
	pageApiMap = {
		'dashboard'		: 'dashboard'
		'users'			: 'users'
		'categories'	: 'categories'
		'articles'		: 'articles'
		'pages'			: 'pages'
		'settings'		: 'settings'
		'text'			: 'text'
	}

	# Every major tab, when activated for the first time will render their default view
	for tabKey, apiKey of pageApiMap then do (tabKey, apiKey) ->
		A.events.on "tabs:menu:#{tabKey} load", loadFn = (tab) ->
			tab.$content.html ''
			url = BASE_URL + '/' + apiKey
			A.request.get { url }, (err, json) ->
				tab.$content.html json?.html or json?.error

				A.events.emit ["tabs:menu:#{tabKey} loaded", "tabs:menu loaded"], tab
				A.events.emit 'autosize', tab.$content

			return false # halts additional listeners


		A.events.on "tabs:menu:#{tabKey} activated", loadFn

	A.events.on "tabs:menu:editArticle load", (tab, args) ->
		tab.$content.html ''

		{ id } = args

		A.helpers.setUrl BASE_URL + '#!editArticle/' + id

		A.request.get {
			url: BASE_URL + '/article'
			data: { id, view: 'sections/article-edit' }
		}, (err, json) ->
			tab.$content.html json?.html or json?.error # TODO: could make functio to fade this content in for all this kinda stuffs which also emits an event

			A.events.emit ["tabs:menu:editArticle loaded", "tabs:menu loaded"], tab

		return false

	A.events.one "tabs:menu:editArticle activated", (tab) ->
		tab.$button.removeAttr 'data-hidden'

	A.events.on "tabs:menu:editArticle loaded", (tab) ->
		A.markdown tab.$content

	# Initializes editable-ness on these tabs, on load
	A.events.on [
		"tabs:menu:settings loaded"
		"tabs:menu:text loaded"
		"tabs:menu:categories loaded"
	], (tab) ->
		A.editable { findIn: tab.$content, widthOffset: 6 }

	# Init revelear for all loaded tabs
	A.events.on "tabs:menu loaded", (tab) ->
		A.events.emit 'content loaded', tab.$content

	# Should be emit manually whenever we change content which require re-establishing
	A.events.on 'content loaded', ($content) ->
		A.revealer $content
		A.selectize $content
		A.textareaAutosize $content
		A.cloner $content
		A.touchable $content
		A.switch $content
		A.codeMirror $content

		$pubDatePicker = $('.datePicker-plubishDate').datetimepicker {
			onChangeDateTime: (date, $input) ->
				$publishedAt = $pubDatePicker.parent().find '[name=publishedAt]'
				$publishedAt.val date.getTime()
		}

	A.events.on 'cloner:generateSlug', (item) ->
		item.val = A.helpers.slugify item.val

	A.events.on 'cloner:generateSlug', (item) ->
		if item.scope is 'pageEditor'
			$pageKeyInput = item.$scope.find '[name=pageKey]'

			if not $pageKeyInput.data('touched')?
				$pageKeyInput.val A.helpers.camelCase item.val
				$pageKeyInput.trigger 'autosize.resize'

	# Changes the URL when a menu tab is changed
	A.events.on 'tabs:menu activated', (tab, args) ->
		return null if args?.setUrl is false
		
		setUrl BASE_URL + '#!' + tab.name

	#
	# Initialization
	#

	# These build up functionality defined in the HTML
	A.tabs()
	A.popups()
	A.markdown()
	A.events.emit 'content loaded', $('body')

	if not HASHBANG?._tags?.length
		A.tabs.tabs.menu?.articles.switch()


	# Switches to the menu tab according to any present hashbang match on page load
	if HASHBANG?._tags then for key, arg of HASHBANG when key of A.tabs.tabs.menu
		tab = A.tabs.tabs.menu[key]

		if key is 'editArticle'
			if not id = arg._child?._value
				setUrl BASE_URL
				continue

			tab.emit 'load', { id }

		tab.switch { setUrl: false }


	#
	# EDITOR
	#

	# Custom submit for editors
	$('body').on 'click', '.editorSubmit', (event) ->
		event.preventDefault()
		$button = $ this

		$form	= $button.closest 'form'
		method	= $button.attr('formmethod') or $form.attr('method')
		title	= $form.find( '[name=title]' ).val()

		if method.toString().match /delete/i
			popup = A.popups.get 'notify'
			popup.populate(
				'Are you sure you want to <strong>delete</strong> this Article?'
				"""
					<p class="textAlignCenter">#{title}</p>
					<p class="textAlignCenter"><a class="button editorConfirmButton">Delete</a> <a class="button editorCancelButton">Cancel</a></p>
				"""
			)
			.show()

			popup.$body.find('.editorConfirmButton').one 'click', ->
				popup.hide()
				editorButtonSubmit.apply $button

			popup.$body.find('.editorCancelButton').one 'click', ->
				popup.hide()
		else
			editorButtonSubmit.apply $button

	editorButtonSubmit = ->
		$button = $ this

		$form	= $button.closest 'form'
		method	= $button.attr('formmethod') or $form.attr('method')

		A.request {
			method	: $button.attr('formmethod') or $form.attr('method')
			url		: $button.attr('formaction') or $form.attr('action')
			data	: $form.serialize()
		}, (err, json) ->
			popup = A.popups.get 'notify'

			if not json or err or err = json.error
				popup.populate(
					'It failed!'
					"""<p class="textAlignCenter">#{err}</p>"""
				)
				.show()

				return false
			else
				popup.populate(
					'Success'
					"""
						<p class="textAlignCenter">
							Article #{json.id} created or modified<br/>
							<small class="popupCounterNote">Closing this popup in <span class="popupCounter"></span> seconds</small>
						</p>
					"""
				)
				.show()
				.timer popup.$body.find('.popupCounter'), 5000



	#
	# ARTICLES PAGE
	# Article listing, preview buttons
	#

	if ( $articlesPage = $ '.articlesPage, .pagesPage' ).length
		$articlesPage.on 'click', '.articlesTable .titleButton', (event) ->
			event.preventDefault()

			$button	= $ this
			$tr		= $button.closest 'tr'
			$form	= $tr.closest 'form'

			id	= $tr.data 'id'
			url	= $form.attr 'action'

			$tr.addClass 'activeArticle'
			$tr.siblings().removeClass 'activeArticle'

			A.request.get {
				url, data: { id }
			}, (err, json) ->
				$articleWindow = $articlesPage.find '.articleWindow'

				if json?.html?
					$articleWindow.html json.html

				# TODO: handle errors, non-content with an error message/popup/icon

		$articlesPage.on 'click', '.articlesTable [data-button="edit"]', (event) ->
			event.preventDefault()

			$button	= $ this
			$tr		= $button.closest 'tr'

			id = $tr.data 'id'

			tab = A.tabs.tabs.menu.editArticle
			tab.switch()
			tab.emit 'load', { id }

	errorPopup = (err) ->
		popup = A.popups.get 'notify'
		popup.populate(
			'Error'
			err
		)
		.show()

	if ( $loginPage = $ '.loginPage' ).length
		$form = $loginPage.find 'form'
		$form.on 'submit', (event) ->
			event.preventDefault()
			data = $form.serialize()

			A.request {
				method: $form.attr 'method'
				url: $form.attr 'action'
				data
			}, (err, json) ->
				if err or json?.error
					return errorPopup err or json?.error

				window.location.pathname = '/admin' # todo: test

	if ( $categoriesPage = $ '.categoriesPage' ).length
		$categoriesPage.on 'click', '[data-button="addCategory"]',(event) ->
			event.preventDefault()
			$button	= $(this)
			$form	= $button.closest 'form'

			{url, method} = A.helpers.tableButtonOptions $button, $form

			A.request { method, url, data: $form.serialize() }, (err, json) ->
				A.tabs.tabs.menu.categories.emit 'load'


	# Whenever a button with attr [data-button="delete"] is clicked, it will ask for confirmation
	# submit the query and return with removing the row or generating an error popup
	$('body').on 'click.autoform', 'table [data-button="delete"]', (event) ->
		event.preventDefault()

		$button	= $(this)

		# Prompt for delete confirmation

		popup = A.popups.get 'notify'
			.populate(
				'Are you sure you want to <strong>delete</strong> this?'
				"""<p class="textAlignCenter"><a class="button" data-button="accept">Delete</a> <a class="button" data-button="cancel">Cancel</a></p>"""
			)
			.show()

		popup.$body.find('[data-button="cancel"]').one 'click', ->
			popup.hide()

		popup.$body.find('[data-button="accept"]').one 'click', ->
			popup.hide()

			# Go ahead with the request

			options = A.helpers.tableButtonOptions $button

			A.request options, (err, json) ->
				if not err and json?.success
					A.helpers.removeTableRow $button.closest('tr')
				else
					popup.populate(
						'Failure'
						"""#{err or json?.error or 'An unknown error occurred'}"""
					)
					.show()

	$('.logoutButton').on 'click', ->
		A.request.delete {
			url: '/api/session'
		}, (err, json) ->
			window.location = '/admin'

	$('body').on 'click', '.editor .addMdBlock', ->
		$button		= $ this
		$controls	= $button.closest '.inputControls'
		$blocks		= $button.closest '.blocks'
		$block		= $blocks.find('.skeleton-mdBlock').first().clone()

		$existingBlocks = $blocks.find '.block:not(.skeleton)'

		newIndex	= $existingBlocks.length
		blockMdKey	= "blocksMd[#{newIndex}]"
		blockKey	= "blocks[#{newIndex}]"


		$block.removeClass 'skeleton skeleton-mdBlock'
		$block.attr 'data-markdown-scope', blockMdKey

		$block.find('.keyInput').attr "name", "data.blocks[#{newIndex}].key"
		$block.find('.typeInput').attr "name", "data.blocks[#{newIndex}].type"
		$block.find('.blockInput')
			.attr 'name', blockMdKey
			.attr 'data-markdown', blockMdKey

		$block.find('.blockOutput').attr 'data-markdown-output', blockMdKey
		$block.find('.blocksMd').attr 'data-markdown', blockMdKey

		# Output best be different!
		$block.find('textarea.blockOutput').attr 'name', blockKey

		$controls.before $block
		A.markdown $block

	$('body').on 'click', '.editor .addTextBlock', ->
		$button		= $ this
		$controls	= $button.closest '.inputControls'
		$blocks		= $button.closest '.blocks'
		$block		= $blocks.find('.skeleton-textBlock').first().clone()

		$existingBlocks = $blocks.find '.block:not(.skeleton)'

		newIndex	= $existingBlocks.length
		blockKey	= "blocks[#{newIndex}]"

		$block.removeClass 'skeleton skeleton-textBlock'
	
		$block.find('.keyInput').attr "name", "data.blocks[#{newIndex}].key"
		$block.find('.typeInput').attr "name", "data.blocks[#{newIndex}].type"
		$block.find('.blockInput')
			.attr 'name', blockKey
			.attr 'data-code-mirror', ''

		$controls.before $block
		A.codeMirror $block


