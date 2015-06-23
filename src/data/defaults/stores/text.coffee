module.exports =
	data:
		title:
			value: "{{settings.title}}"
			name: "Title"
			description: "Defines the default <title> tag"
			description2: "Notable variables: {{settings}} {{text}}"
			group: "head"

		title_article:
			value: "{{article.title}} - {{settings.title}}"
			name: "Title (Article)"
			description: "Defines the <title> tag for an article page"
			description2: "Notable variables: {{article}} {{settings}} {{text}}"
			group: "head"

		title_search:
			value: "{{search}} - {{settings.title}}"
			name: "Title (Search)"
			description: "Defines the <title> tag for the search page"
			description2: "Notable variables: {{search}} {{article}} {{settings}} {{text}}"
			group: "head"

		description:
			value: ""
			name: "Description"
			description: "Defines the default <description> tag"
			description2: "Notable variables: {{article}} {{settings}} {{text}}"
			input: "textarea"
			group: "head"

		description_article:
			value: ""
			name: "Description (Article)"
			description: "Defines the <description> tag for an article page"
			description2: "Notable variables: {{article}} {{settings}} {{text}}"
			input: "textarea"
			group: "head"

		description_search:
			value: ""
			name: "Description (Search)"
			description: "Defines the <description> tag for a search page"
			description2: "Notable variables: {{search}} {{article}} {{settings}} {{text}}"
			input: "textarea"
			group: "head"

		robots:
			value: "noindex"
			name: "Robots"
			description: "Defines the <meta name='robots'> tag for search engine bot rules"
			description2: "This is a comma seperated list. Setting 'Robots' must be enabled for this to work.<br/><b>Values</b>: noindex, nocrawl, nofollow, noimageindex, noarchive, nosnippet, noodp"
			group: "head"

		robots_header:
			value: "noindex"
			name: "Robots HTTP Header"
			description: "Defines the X-Robots-Tag in the HTTP header"
			description2: "This is a comma seperated list. Setting 'Robots' must be enabled for this to work.<br/><b>Values</b>: noindex, nocrawl, nofollow, noimageindex, noarchive, nosnippet, noodp"
			group: "head"