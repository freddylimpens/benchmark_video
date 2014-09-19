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
    console.log(" INIT: layer height = ", $(html_content).find("article").height())
    # FIXME : deal with options
    #L.setOptions(this, options);

onAdd: (map) ->
    this._map = map;
    #create a DOM element and put it into one of the map panes
    if (this._map.options.zoomAnimation && L.Browser.any3d)
        L.DomUtil.addClass(this._el, 'leaflet-zoom-animated')
    else
        L.DomUtil.addClass(this._el, 'leaflet-zoom-hide')
        
    #L.DomUtil.addClass(this._el, 'leaflet-zoom-animated')
    console.log(' ## article element = ', this._el)
    map.getPanes().overlayPane.appendChild(this._el)
    console.log(" *** layer added ***")
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

_animateZoom: (e)->
    #console.log(" animating zoom...") 
    topLeft = this._map._latLngToNewLayerPoint(this._bounds.getNorthWest(), e.zoom, e.center)
    bottomRight = this._map._latLngToNewLayerPoint(this._bounds.getSouthEast(), e.zoom, e.center)
    new_bounds = new L.Bounds(topLeft, bottomRight)
    translateString = L.DomUtil.getTranslateString(new_bounds.getCenter()) 
    console.log(" Animate zoom : center = ", new_bounds.getCenter())
    #console.log(" ANIMATE ZOOME : translateString = ", translateString)
    this._el.style[L.DomUtil.TRANSFORM] = translateString + ' scale(' + e.scale + ') ';
    # transformString = L.DomUtil.getTranslateString(new_bounds.getCenter()) + ' scale(' + e.scale + ') '
    # $(this._el).css({ 
    #                 '-webkit-transform': transformString
    #                 '-moz-transform': transformString
    #                 '-o-transform': transformString
    #                 'transform': transformString
    #             })

_reset: () ->
    #update layer's position with bounds
    html_layer = this._el
    # GEO => PIXEL
    bounds = new L.Bounds(
        this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
        this._map.latLngToLayerPoint(this._bounds.getSouthEast())
        )
    L.DomUtil.setPosition(html_layer, bounds.getCenter())
    console.log(" Reset : center = ", bounds.getCenter())
    # SCALING : computed after currently projected size 
    c_z = this._map.getZoom()
    currently_projected_size = bounds.max.x - bounds.min.x
    # FIXME : there should not be any template-dependent id, class or anything here
    real_size = $(html_layer).find("article").width()
    ts = real_size / currently_projected_size
    transformScale = "scale("+(1/ts)+")"
    # FIXME : should be template-independent, hence merely applying style on main element
    # => now this is due to conflict between global transform applied by leaflet and the local one we apply here   
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
        
        @$scope.clusters.push(cluster)
        # FIXME : there should not be any template-dependent id, class or anything here
        elem_height = $(element).find("article").height()
        elem_width = $(element).find("article").width()
        console.log(" *** ADDING LAYER *** h = "+elem_height+" w = "+elem_width)
        #calculate the edges of the image, in coordinate space
        i = cluster.column
        j = cluster.order_in_column
        console.log(" i = "+i+" j = "+j)
        nE_x = @$scope.WIDTH * (i + 1) 
        sW_x = @$scope.WIDTH * i + 500
        if j > 0
            nE_y = @$scope.clusters_bounds[i][j-1].sW_y
            sW_y = @$scope.clusters_bounds[i][j-1].sW_y + elem_height + 500 # FIXME ! get padding or absolute coordinates
        else if j == 0
            nE_y = 0
            sW_y =  elem_height + 500 # FIXME ! get padding or absolute coordinates
            @$scope.clusters_bounds.push([]) # required to avoid being out of bound
        @$scope.clusters_bounds[i][j] =
            {
                nE_x : nE_x
                nE_y : nE_y
                sW_x : sW_x
                sW_y : sW_y
            }
        console.log(" Global Bounds object =", @$scope.clusters_bounds)
        southWest = @$scope.map.unproject([sW_x, sW_y], @$scope.map.getMaxZoom());
        northEast = @$scope.map.unproject([nE_x, nE_y], @$scope.map.getMaxZoom());
        layer_bounds = new L.LatLngBounds(southWest, northEast)
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
                fadeAnimation: true
                #touchZoom: true
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
        templateUrl: 'views/cluster.html'

        link: ($scope, element, attrs, ctrl, $timeout) ->
            # get element width and height to place it correctly    
            console.log("current cluster id = ", $scope.cluster.id)
            # We watch the number of children to the "posts" node 
            #   when the ng-repeat loop within the posts has finished, 
            #   we can add the layer knowing then the cluster's height
            watch = $scope.$watch(()->
                return $(element[0]).find('.posts').children().length
            , ()-> 
                $scope.$evalAsync(()->
                    # Finally, directives are evaluated
                    # and templates are renderer here
                    children = $(element[0]).find('.posts').children()
                    ctrl.addHtmlLayer(element[0], $scope.cluster)
                )
            )        
            
            
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
