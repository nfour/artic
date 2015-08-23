# Artic
Artic is a CMS for **Artic**les, in node_modules form.

**Status**: `[ ! UNSTABLE CONCOCTION ! ]`

With minimal configuration:
- Start up a server, utilizing [Lance](https://github.com/nfour/lance)
- Serve an admin iterface at `http://*/artic`
- Create a `sqlite` database for persistance
	+ Also supports `postgres`, `mysql`, `mariadb`
- Artic remains a node module and does not impose a folder structure
- Serves a modular template/theme frontend at `http://*/`
	+ Populates a default template on instantiation

With further interfacing with Artic:
- Utlize internal routers
- Overwride internal controllers, handlers etc.
- Modify database structure, extend models and stores

Artic is cleanly written and highly modular, focused on handling `articles` and not much else. You specify the dependencies you want Artic to use for your templates.

Because Artic is just another node module and is so modular, you can use as little or as much of it as necessary. Got your own server code? That's fine. Handling your own CSS compilation? Also fine.

See [Lance](https://github.com/nfour/lance) for lower-level integration.

## Data features
- Articles
	+ The highest level data structure.
- Blocks
	+ These make up an article.

## Templates
Artic serves a template to the frontend, usually from    
`./<project directory>/templates/<template>`

When you first start Artic that directory will be populated with the default template.

A template can contain a `template.json`:
```js
{
	// Defaults to the directory name when not set
	"name"        : "MyTheme2"
,	"author"      : "nfour"
,	"description" : "Just a theme"
	
	// Files to be compiled to the public/static directory
	// See Lance templating for more information
,	"bundle": {
		"./css/destination.css" : "./source.styl"
	,	"./js/destination.js"   : "./app.coffee"
	}
}
```

All fields are optional.

### Bundled files
Any bundled files in the `template.json` will be compiled and accessable from    
`/static/<template>/<destination path>`.

```js
{
	"bundle": { "dest/in/ation.css": "original/file.css" }
}
```

Can be referenced at.
`http://*/static/MyTheme2/dest/in/ation.css`

## Examples
`npm install artic`

```coffee
Artic = require 'artic'

artic = new Artic {
	template: 'myTemplate'
}

artic.initalize().then -> # Done
```




