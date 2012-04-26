#<< theoricus/utils/string_util

###
	Router inspired by:
	https://github.com/haithembelhaj/RouterJs
###

class Router
	routes: []
	listeners: []

	trigger: true
	initialized: false

	constructor:( @the )->
		@map route, opts.to, opts.at for route, opts of @the.boot.routes
		History.Adapter.bind window, 'statechange', =>
			@route History.getState()

	on_change:( listener )->
		@listeners.push listener

	init:->
		return if @initialized
		@initialized = true

		url = window.location.pathname
		url = @the.boot.boot if url == "/"

		@run url
	
	map:( route, to, at )->
		@routes.push new theoricus.core.Route route, to, at

	route:( state )->
		if @trigger
			url = state.title or state.hash
			for route in @routes
				if route.matcher.test url
					params = route.matcher.exec( url ).slice 1
					listener route, params for listener in @listeners

		@trigger = true

	navigate:( url, trigger = true, replace = false )->
		@trigger = trigger
		History[if replace then "replaceState" else "pushState"] null, url, url

	run:( url, trigger = true )->
		# console.log "Router.run( '#{url}' )"
		@trigger = trigger
		@route {title:url}

	go:( index )->
		History.go index

	back:()->
		History.back()

	forward:()->
		History.forward()



class Route
	StringUtil = theoricus.utils.StringUtil

	@named_param_reg: /:\w+/g
	@splat_param_reg: /\*\w+/g

	constructor:( route, to, at )->
		@raw = route:route, to:to, at:at
		
		@matcher = route.replace Route.named_param_reg, '([^\/]+)'
		@matcher = @matcher.replace Route.splat_param_reg, '(.*?)'
		@matcher = new RegExp "^#{@matcher}$"

		@controller = to.split( "/" )[0]
		@action = to.split( "/" )[1]

		if /\#/g.test at
			@target_route = at.split( "#" )[0]
			@target_el = "#" + at.split( "#" )[1]
		else
			@target_route = null
			@target_el = at