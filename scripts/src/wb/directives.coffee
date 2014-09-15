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
    console.log(" init layer : bounds valid ?", this._bounds.isValid())
    console.log(" init layer : bounds = ", this._bounds)
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
    # GEO => PIXEL
    bounds = new L.Bounds(
        this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
        this._map.latLngToLayerPoint(this._bounds.getSouthEast())
        )
    L.DomUtil.setPosition(html_layer, bounds.getCenter())
    console.log(" RESET : setting bounds = ", bounds)
    # SCALING : computed after currently projected size 
    c_z = this._map.getZoom()
    console.log("RESET : zoom level = " + c_z)
    currently_projected_size = bounds.max.x - bounds.min.x
    # !!! FIXME !!! = should get size with generic node and not specific !!!
    real_size = $(html_layer).find("#article1").width()
    ts = real_size / currently_projected_size
    console.log(" currently_projected_size = "+currently_projected_size+" real_size = "+real_size+"transformScale= "+ts)
    transformScale = "scale("+(1/ts)+")"
    # FIXME : we now apply zoom to second child element (hacky!) 
    #         => should be applied to main element   
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
    constructor: (@$scope, @$rootScope) ->
        @$scope.html_layer_instances = []
        @$scope.clusters = []
        @$scope.clusters_bounds = [[]]
        @$scope.WIDTH = @$rootScope.config.constant_width

    # Add HtmlContent Layer
    addHtmlLayer:(element, cluster) =>
        # FIXME : should get generic element
        @$scope.clusters.push(cluster)
        elem_height = $(element).find("#article1").height()
        elem_width = $(element).find("#article1").width()
        #calculate the edges of the image, in coordinate space
        # ==>> should get global pixel coordinate from directive controller ??
        i = cluster.column
        j = cluster.order_in_column
        console.log(" i = "+i+" j = "+j)
        nE_x = @$scope.WIDTH * (i + 1) 
        sW_x = @$scope.WIDTH * i
        if j > 0
            nE_y = @$scope.clusters_bounds[i][j-1].sW_y
            sW_y = @$scope.clusters_bounds[i][j-1].sW_y + elem_height
        else if j == 0
            nE_y = 0
            sW_y =  elem_height
            @$scope.clusters_bounds.push([]) # required to avoid being out of bound
        @$scope.clusters_bounds[i][j] =
            {
                nE_x : nE_x
                nE_y : nE_y
                sW_x : sW_x
                sW_y : sW_y
            }
        console.log(" Bounds =", @$scope.clusters_bounds)
        console.log(" Max zoom ?? = ", @$scope.map.getMaxZoom())
        # FIXME : get the rigth value for zoom or scale on wich projection works 
        southWest = @$scope.map.unproject([sW_x, sW_y], @$scope.map.getMaxZoom());
        northEast = @$scope.map.unproject([nE_x, nE_y], @$scope.map.getMaxZoom());
        layer_bounds = new L.LatLngBounds(southWest, northEast)
        console.log(" >> LatLng Bounds = ", layer_bounds)
        aLayer = new HtmlLayer(layer_bounds, element)
        @$scope.map.addLayer(aLayer)

module.controller("LeafletController", ['$scope', '$rootScope', LeafletController])

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
            $scope.map = new L.Map($el,
                zoomControl: true
                zoomAnimation: true
                minZoom: 1
                maxZoom: 5
                crs: L.CRS.Simple
                # crs: L.CRS.EPSG4326
            )
            # Center Change callback
            $scope.$watch("center", ((center, oldValue) ->
                    console.debug("map center changed")
                    $scope.map.setView([center.lat, center.lng], center.zoom)
                ), true
            )
    }
])

module.directive("htmlCluster", [() ->
    return {
        restrict: 'E'
        require: '^leaflet'

        transclude: true
        replace: true
        scope:
            cluster: "=cluster"
        templateUrl: 'views/article_1.html'

        link: ($scope, element, attrs, ctrl) ->
            # get element width and height to place it correctly    
            console.log("current cluster id = ", $scope.cluster.id)        
            ctrl.addHtmlLayer(element[0], $scope.cluster)
            
            # -- ARTE player stuff
            # listen to the arte_vp_player_config_ready event
            # container = $(element).find('.video-container')    
            # hack to trigger click event and generate iframe code
            # $("div[arte_vp_url]").trigger("click");
            # following does not work (works only if the code is loaded from arte servers due to domain check)
            # container.on("arte_vp_player_config_ready", (e)->
            #     console.debug(" forcing HTML5")
            #     #force HTML5
            #     angular.element('iframe')[0].contentWindow.arte_vp.parameters.config.primary = "html5"
            # )
            
    }
])
