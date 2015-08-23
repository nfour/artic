### v3.0.0
```
Goal:
	Simplify Artic's bahavior and give it a clear scope/purpose.
	Artic should be able to become a blog platform, but should not
	impose that kind of use-case or structure.

	The word Article is defined as: "a particular item or object".

	Articles are made of blocks.
	Articles are relational via meta data.
	That's about it.

Structure:
	Simplified down to the fundamentals, with events and hooks to extend functionality.

	-	ARTICLES are the top-level data structure, built in BLOCKS
		-	ARTICLES being fulltext searchable on supported BLOCKS
		-	BLOCKS contain data
			-	Arrays, Objects containing arbitrary data or nested BLOCKS
			-	HTML / Markdown

		-	Article TEMPLATES structure article creation
			A drag/drop interface, highly visual
			-	Article creation can be defaulted to a TEMPLATE
			-	TEMPLATES can have default META, such as a category

		-	Article META scopes ARTICLES
			-	Categories are META
			-	Meta are META
			-	META can be nested
				Such as Categories > Movies > Action

	-	SETTINGS control Artic
	-	USERS to manage both staff and users
		-	USER ROLES to manage permissions

Usage:
	Artic's setup and usage is non-conventional.

	ARTICLES should be used for ALL website data.
	Artic is essentially a database interface CRM, it tries
	not to make too many assumptions about the data to allow
	for flexibility.

	A blog example:
		This example will show the flow for creation of a site
		featuring a blog.

		Note: This is only one way, but could be done much simpler
		or more thorough.

		-	Create a TEMPLATE, as "Blog Post"
			Blocks:
				"Title" (Text, Searchable)
				"Body" (Markdown, Searchable)

			Meta:
				"Blog Post"

		-	Create a TEMPLATE, as "Blog Page"
			Blocks:
				"headTitle"
				"headDescription"
				"articlesPerPage"
				"paginationMax"

			Meta:
				"Page"
				
		-	Create an ARTICLE, as "Site"
			Blocks:
				"sidebarBlurb" (Markdown)
				"footerLinks" (Markdown)
				"announcement" (Markdown)

			Meta:
				"Site"

		-	Create an ARTICLE from TEMPLATE "Blog Page", as "Home Page"
		-	Create an ARTICLE from TEMPLATE "Blog Post", as "Hello World!"


		First, we fetch the "Site" Article on each request,
		preferrebly storing it in memory. Then use that to build
		the semi-static content such as the "footerLinks" and
		"sidebarBlurb".

		We then wire up a controller for the path "/myblog"
		to fetch the "Home Page" ARTICLE matching META "Page".
		Using this you can construct the blog page.

		Then, fetch each "Blog Post" ARTICLE of META "Blog Post", ordering
		and filtering them as you please.

		In a few short minutes a blog is up. With this
		data structure websites can be built without limitations from
		the database.

	Programmatic usage:
		In templating, generating of HTML markup, Articles are fetched
		from Artic, then the blocks can be accessed via

		`article.block('blockName')`
		or
		`block.render() for block in article.blocks`

		or the raw un-generated/un-transformed data via

		`block.value for block in article.blocks`

		This also may be flexible enough to allow for ReactJs
		integration in the future.


	BLOCKS can be inline-edited:
		By using the function `article.block("someBlock")
		a element can be generated with a key like so
		<span artic-key="0.someBlock">Woo!</span>
		It is then trivial to make such content editable inline, thus
		after the initial setup above is complete, a website can enter
		a "edit mode" on the fly for any logged in admin on the public
		facing side of the site.
```