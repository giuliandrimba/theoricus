## Router & Route logic inspired by RouterJS:
## https://github.com/haithembelhaj/RouterJs

###*
  Core module
  @module core
###

StringUril = require 'theoricus/utils/string_util'
Route = require 'theoricus/core/route'

require 'history'

Factory = null

###*
  Proxies browser's History API, routing request to and from the aplication
  @class Router
###
module.exports = class Router

  ###*
    Array storing all the routes defined in the application's route file.

    @property {Array} routes
  ###
  routes: []

  ###*
    If false, doesn't handle the url route.

    @property {Boolean} trigger
  ###
  trigger: true

  ###*
  @class Router
  @constructor
  @param @the {Theoricus} Shortcut for app's instance
  @param @on_change {Function} state/url change handler
  ###
  constructor:( @the, @Routes, @on_change )->
    Factory = @the.factory

    for route, opts of @Routes.routes
      @map route, opts.to, opts.at, opts.el, @

    History.Adapter.bind window, 'statechange', =>
      @route History.getState()

    setTimeout =>
      url = window.location.pathname
      url = @Routes.root if url == "/"
      @run url
    , 1

  ###*
  Creates and store a route
  @method map
  @param route {String}
  @param to {String} Controller and action to which the route will be sent.
  @param at {String} Route to be called as a dependency.
  @param el {String} CSS selector to define where the template will be rendered.
  ###
  map:( route, to, at, el )->
    @routes.push route = new Route route, to, at, el, @
    return route

  route:( state )->

    if @trigger

      # url from HistoryJS
      url = state.hash || state.title

      # FIXME: quickfix for IE8 bug
      url = url.replace( '.', '' )

      #remove base path from incoming url
      ( url = url.replace @the.base_path, '' ) if @the.base_path?

      # removes the prepended '.' from HistoryJS
      url = url.slice 1 if (url.slice 0, 1) is '.'

      # adding back the first slash '/' in cases it's removed by HistoryJS
      url = "/#{url}" if (url.slice 0, 1) isnt '/'

      # fallback to root url in case user enter the '/'
      url = @Routes.root if url == "/"

      # search in all defined routes
      for route in @routes
        if route.test url
          return @on_change route, url

      # if none is found, tries to render based on default
      # controller/action settings
      url_parts = (url.replace /^\//m, '').split '/'
      controller_name = url_parts[0]
      action_name = url_parts[1] or 'index'

      @the.factory.controller controller_name, (controller)=>

        # if controller is found, route call to it
        if controller?
          route = @map url, "#{controller_name}/#{action_name}", null, 'body'
          return @on_change route, url

        # otherwise renders the not found route
        else

          for route in @routes
            if route.test @Routes.notfound
              return @on_change route, url

    @trigger = true

  navigate:( url, trigger = true, replace = false )->
    @trigger = trigger

    action   = if replace then "replaceState" else "pushState"
    History[action] null, null, url

  run:( url, trigger = true )=>
    ( url = url.replace @the.base_path, '' ) if @the.base_path?

    url = url.replace /\/$/g, ''

    @trigger = trigger
    @route { title: url }

  go:( index )->
    History.go index

  back:()->
    History.back()

  forward:()->
    History.forward()
