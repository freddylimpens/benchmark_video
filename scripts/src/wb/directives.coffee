# -*- tab-width: 4 -*-
# HTML Layer
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
    console.log("[RESET] html_layer = ", html_layer)
    console.log("[RESET] html_layer . childNodes[1] = ", html_layer.childNodes[1])
    bounds = new L.Bounds(
        this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
        this._map.latLngToLayerPoint(this._bounds.getSouthEast()))
    L.DomUtil.setPosition(html_layer, bounds.getCenter())
    # apply scale with current zoom
    c_z = this._map.getZoom()
    html_layer.childNodes[1].style =  'transform: scale('+ c_z*0.05+','+c_z*0.05+');'
    #html_layer.style[L.DomUtil.TRANSFORM] = L.DomUtil.getTranslateString(bounds.getCenter()) + 'scale('+ c_z*0.05+','+c_z*0.05+');'
    console.log("style changed ?", html_layer.style)
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
                maxZoom: 20
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

    }
])
