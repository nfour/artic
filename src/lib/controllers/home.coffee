A = require '../app'
{ merge } = A.utils

module.exports = (o) ->
	{ path, template, session } = o
	{ page } = path
	{ data } = template

	template.view	= 'home'
	page			?= 1
	
	user = yield session.use()

	# todo: pagination n stuff with page

	articles = yield A.db.Articles()
		.limit 40
		.select()

	merge data, { user, articles }

	yield return