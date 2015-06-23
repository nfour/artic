A		= require '../app'
Promise	= require 'bluebird'
path	= require 'path'
fs		= Promise.promisifyAll require 'fs'
wrench	= require 'wrench'

{ merge, clone, typeOf } = A.utils

module.exports = ->
	# Find template folder or create default template
	if A.cfg.templateDirectory
		A.paths.template = if /^\//.test A.cfg.templateDirectory
			A.cfg.templateDirectory
		else
			path.join A.paths.root, A.cfg.templateDirectory
	else
		A.paths.template = A.cfg.templateDirectory or path.join A.paths.root, './templates', A.cfg.template

	# Check for a template match, if none build the directory
	if fs.existsSync A.paths.template
		console.log 'Using template'.grey, A.cfg.template.cyan
		A.template = A.cfg.template
	else
		A.template = 'default'
		console.error 'Warning'.yellow + ": Template #{ A.template.cyan }, ( resolved to #{ A.paths.template.cyan } ) not found"

		# Step back one folder, then into 'default', assuming /templates/template structure
		A.paths.template	= path.join ( path.dirname A.paths.template ), A.template
		defaultTemplateDir	= path.join A.paths.artic, './templates/default'

		if fs.existsSync A.paths.template
			console.log 'Using template'.grey, A.template.cyan
		else
			console.log 'Creating template directory', A.paths.template.cyan
			console.log 'copying over from', defaultTemplateDir

			# Makes /project/templates folder
			wrench.mkdirSyncRecursive path.dirname A.paths.template
			
			# Makes /project/templates/default folder, copies files from /artic/template
			if not wrench.copyDirSyncRecursive defaultTemplateDir, A.paths.template, { forceDelete: false, preserveFiles: true }
				console.log 'Using template'.grey, A.template.cyan
			else
				console.error 'Warning'.yellow + ": Failed to make or cant copy default template to #{ A.paths.template.cyan }"
				console.error 'Error'.red + ": No template avaliable"

	#
	# User templater
	#

	merge A.cfg.lance.templater,
		findIn	: A.paths.template
		saveTo	: A.paths.static

	A.templater = A.lance.templater = new A.lance.Templater A.cfg.lance.templater, A.lance
	A.locals	= A.templater.locals

	merge A.locals,
		cfg		: A.cfg
		utils	: A.utils
		moment	: require 'moment'
		
	A.locals[key] = store.values for key, store of A.db.stores
		

	#
	# Admin templater
	#

	merge A.cfg.adminTemplater,
		saveTo	: A.paths.adminStatic
		root	: A.paths.artic

	A.adminTemplater		= new A.lance.Templater A.cfg.adminTemplater, A.lance
	A.adminTemplater.locals	= A.locals

	if not A.cfg.disableTemplaterInitialization
		yield Promise.all [
			A.templater.bundle()
			A.adminTemplater.bundle()
		]

		if not A.cfg.ignoreAssets
			Promise.all( [
				A.templater.assets.syncDirectory()
				A.adminTemplater.assets.syncDirectory()
			]).then()

	A.emit 'templates.ready'
	
	yield return