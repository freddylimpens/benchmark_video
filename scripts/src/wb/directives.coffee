# -*- tab-width: 4 -*-
# HTML Layer
# FIXME : should be moved to separate file, but coffe compilation prevents from loading global object 
HtmlLayer = L.Class.extend({

options:
    opacity: 1
    alt: ''
    zoomAnimation: true

initialize: (bounds, html_content, options) ->
    #save position of the layer or any options from the constructor
    console.log("INIT : setting bounds")
    this._bounds = L.latLngBounds(bounds)
    this._el = html_content
    # FIXME : deal with options
    #L.setOptions(this, options);

onAdd: (map) ->
    this._map = map;
    #create a DOM element and put it into one of the map panes
    #L.DomUtil.addClass(this._el, 'leaflet-zoom-animated')
    console.log(' ## article element = ', this._el)
    map.getPanes().overlayPane.appendChild(this._el)
    console.log("layer added")
    #add a viewreset event listener for updating layer's position, do the latter
    map.on('viewreset', this._reset, this)
    map.on('zoomanim', this._animateZoom, this)
    this._reset()

# FIXME : is it usefull ???
getEvents: ()->
    events = 
        viewreset: this._reset
        zoomanim: this._animateZoom
    
    if (this._zoomAnimated)
        events.zoomanim = this._animateZoom
    
    return events

getBounds: ()->
    return this._bounds

onRemove: (map) ->
    #remove layer's DOM elements and listeners
    map.getPanes().overlayPane.removeChild(this._el)
    map.off('viewreset', this._reset, this)

# FIXME : does not work currently
_animateZoom: (e)->
    # built in animation mechanism depends on projected size (geo > screen space); 
    # hence, the following does not play well with zoom-only variation of size (see _reset)   
    console.log(" animating zoom...") 
    topLeft = this._map._latLngToNewLayerPoint(this._bounds.getNorthWest(), e.zoom, e.center)
    size = this._map._latLngToNewLayerPoint(this._bounds.getSouthEast(), e.zoom, e.center).subtract(topLeft)
    scale = this._map.getZoomScale(e.zoom)
    origin = topLeft._add(size._multiplyBy((1 - 1 / scale) / 2));
    this._el.childNodes[1].style[L.DomUtil.TRANSFORM] = L.DomUtil.getTranslateString(origin) + ' scale(' + scale + ') ';

_reset: () ->
    #update layer's position with bounds
    html_layer = this._el
    bounds = new L.Bounds(
        this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
        this._map.latLngToLayerPoint(this._bounds.getSouthEast()))
    L.DomUtil.setPosition(html_layer, bounds.getCenter())
    # apply scale with current zoom
    c_z = this._map.getZoom()
    transformScale = 'scale('+ c_z*0.1+')'
    # FIXME : we now apply zoom to second child element (hacky!) 
    #         => should be applied to main element   
    #html_layer.childNodes[1].style =  'transform: scale('+ c_z*0.05+','+c_z*0.05+');'
    elem_scaled = $(html_layer.childNodes[1])
    elem_scaled.css({
                    '-webkit-transform': transformScale
                    '-moz-transform': transformScale
                    '-o-transform': transformScale
                    'transform': transformScale
                })
})

###################################

module = angular.module("leaflet-directive", [])

class LeafletController
    constructor: (@$scope) ->
        @$scope.marker_instances = []

    # Add HtmlContent Layer
    addHtmlLayer:(aLayer) =>
        @$scope.map.addLayer(aLayer)
    
module.controller("LeafletController", ['$scope', LeafletController])

module.directive("leaflet", ["$http", "$log", "$location", ($http, $log, $location) ->
    return {
        restrict: "E"
        replace: true
        transclude: true
        scope:
            center: "=center"
            tilelayer: "=tilelayer"
            path: "=path"
            maxZoom: "@maxzoom"

        template: '<div class="angular-leaflet-map"><div ng-transclude></div></div>'

        controller: 'LeafletController'

        link: ($scope, element, attrs, ctrl) ->
            $el = element[0]
            console.log(" Primary directive element = ", element)
            $scope.map = new L.Map($el,
                zoomControl: true
                zoomAnimation: true
                minZoom: 1
                maxZoom: 10
                # crs: L.CRS.EPSG4326
            )
            # Center
            # Change callback
            $scope.$watch("center", ((center, oldValue) ->
                    console.debug("map center changed")
                    $scope.map.setView([center.lat, center.lng], center.zoom)
                ), true
            )
            maxZoom = $scope.maxZoom or 12
            
    }
])

module.directive("htmlCluster", [() ->
    return {
        restrict: 'E'
        require: '^leaflet'

        transclude: true
        replace: true
        templateUrl: 'views/article_1.html'

        link: ($scope, element, attrs, ctrl) ->
            layer_bounds = L.latLngBounds(L.latLng(0,0), L.latLng(-40,40))
            ctrl.addHtmlLayer(new HtmlLayer(layer_bounds, element[0]))
            
            # -- ARTE player stuff
            # listen to the arte_vp_player_config_ready event
            #container = $(element).find('.video-container')    
            # hack to trigger click event and generate iframe code
            #$("div[arte_vp_url]").trigger("click");
            # following does not work (works only if the code is loaded from arte servers due to domain check)
            # container.on("arte_vp_player_config_ready", (e)->
            #     console.debug(" forcing HTML5")
            #     #force HTML5
            #     angular.element('iframe')[0].contentWindow.arte_vp.parameters.config.primary = "html5"
            # )
            
    }
])
