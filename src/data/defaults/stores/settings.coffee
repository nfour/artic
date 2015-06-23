module.exports =
	data:
		url:
			value: ""
			name: "Site URL"
			description: "The URL used to construct links"
			description2: "Notable variables: {{settings}} {{text}}"
			group: "core"

		title:
			value: "Artic"
			name: "Site Title"
			description: "The site's display name"
			description2: "Notable variables: {{settings}} {{text}}"
			group: "core"

		robots:
			value: false
			name: "Robots"
			description: "Let search engine robots index the site?"
			input: "boolean"
			group: "core"

		articleLimit:
			value: "20"
			name: "Article Limit"
			description: "The default limit for all article listings"
			input: "number"
			group: "limits"

		articleLimit_home:
			value: "20"
			name: "Home Article Limit"
			description: "The front page's article limit"
			input: "number"
			group: "limits"

		articleLimit_search:
			value: "30"
			name: "Search Article Limit"
			description: "The search page's article limit"
			input: "number"
			group: "limits"

		email_enabled:
			value: false
			name: "Enable"
			description: "Enable email functionality?"
			input: "boolean"
			group: "email"

		email:
			value: ""
			name: "Email"
			description: "The email address which will serve emails"
			group: "email"

		emailPass:
			value: ""
			name: "Password"
			description: "The email login password"
			group: "email"

		one:
			value: false
			name: "Enable"
			description: "Enable email functionality?"
			input: "boolean"
			group: "misc"

		two:
			value: ""
			name: "Email"
			description: "The email address which will serve emails"
			group: "misc"

		three:
			value: ""
			name: "Password"
			description: "The email login password"
			group: "misc"