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
    console.log("Init HTML Layer")
    this._el = html_content
    this._bounds = L.latLngBounds(bounds)
    # FIXME : following works, but have to check with new template; otherwise would need to 
    #       fetch another element for getting real size like so: this._real_size = $(html_content).find("article").width()
    this._real_size = $(html_content).width()
    #console.log(" init layer : bounds valid ?", this._bounds.isValid())
    #console.log(" init layer : bounds = ", this._bounds)
    # FIXME : deal with options ??
    #L.setOptions(this, options);

onAdd: (map) ->
    #create a DOM element and put it into one of the map panes
    this._map = map;
    # Test to activate or not zoom animation for browsers not supporting 3d acceleration 
    if (this._map.options.zoomAnimation && L.Browser.any3d)
        L.DomUtil.addClass(this._el, 'leaflet-zoom-animated')
    else
        L.DomUtil.addClass(this._el, 'leaflet-zoom-hide')
    map.getPanes().overlayPane.appendChild(this._el)
    #add a viewreset event listener for updating layer's position, do the latter
    map.on('viewreset', this._reset, this)
    map.on('zoomanim', this._animateZoom, this)
    this._reset()
    #console.log(" *** layer added ***")

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
    this._el.style[L.DomUtil.TRANSFORM] = translateString + ' scale(' + e.scale + ') ';
    # !FIXME! : check that above version works on all platform, if not try following :
    # transformString = L.DomUtil.getTranslateString(new_bounds.getCenter()) + ' scale(' + e.scale + ') '
    # $(this._el).css({ 
    #                 '-webkit-transform': transformString
    #                 '-moz-transform': transformString
    #                 '-o-transform': transformString
    #                 'transform': transformString
    #             })

_reset: () ->
    # POSITION : update layer's position with new bounds
    html_layer = this._el
    # GEO bounds to PIXEL bounds
    bounds = new L.Bounds(
        this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
        this._map.latLngToLayerPoint(this._bounds.getSouthEast())
        )
    L.DomUtil.setPosition(html_layer, bounds.getCenter())
    # SCALING : computed after currently projected size 
    currently_projected_size = bounds.max.x - bounds.min.x
    ts = this._real_size / currently_projected_size
    transformScale = "scale("+(1/ts)+")"
    # FIXME : conflict between global transform applied by leaflet to main node (html_layer) 
    # and the local one we apply here, => apply transform on child node  
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
                touchZoom: false
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

class ClusterController
    constructor: (@$scope, @$rootScope) ->
        console.log(" ++ Cluster Controler ++ current cluster id = ", $scope.cluster.id)
        @$scope.sequence_loaded = false
        @$scope.sequence_playing = false
        @$scope.sequence_paused = false

        # REMOVE ME ?
        @$scope.showIframe = false
        @$scope.loadSequence = this.loadSequence
        @$scope.loadPlayer = this.loadPlayer

    loadSequence: (sequence) =>
        """
        Load a video sequence 
        """
        console.log(" +++ loading/playing sequence for cluster id = ", @$scope.cluster.id )
        console.log(" ARTE player ?", @$scope.arte_player)
        console.log(" ALready loaded ?? ", @$scope.sequence_loaded)

        @$scope.showIframe = true
        @$scope.sequence_iframe_src = sequence.iframe_src
        
        # without iFrame == with arte iFramizator
        if  !@$scope.sequence_loaded
            console.log(" Iframizator !!", @$scope.arte_player_container_object)
            arte_vp_iframizator(@$scope.arte_player_container_object)
            
        else if @$scope.sequence_loaded && !@$scope.sequence_playing
            console.log(" PLAY ")
            @$scope.arte_player.play()
            @$scope.sequence_playing = true

        else if @$scope.sequence_loaded && @$scope.sequence_playing
            console.log(" PAUSE ")
            @$scope.arte_player.pause()
            @$scope.sequence_playing = false
            @$scope.sequence_paused = true

    loadPlayer: ()=>
        """
        load sequence for the iframe case (deprecated)
        """
        # iFrame case
        if  @$scope.showIframe
            console.log(" iframe loaded with arte plauyer")
            console.log("cluster element in controler", @$scope.cluster_elem)
            @$scope.iframe_elem = $(@$scope.cluster_elem).find('.iframeseq')
            console.log("iframe element in controler", @$scope.iframe_elem)
            arte_player = @$scope.iframe_elem[0].contentWindow.arte_vp_player
            console.log("arte player in controler", arte_player)
            arte_player.setControls(false)
            arte_player.onReady(()=>
                    arte_player.setControls(false)
                    arte_player.play()
                )

module.controller("ClusterController", ['$scope', '$rootScope', ClusterController])

###
Directive to control loading and binding for each cluster linked to a given theme
###
module.directive("htmlCluster", ["$timeout", ($timeout) ->
    return {
        restrict: 'E'
        require: '^leaflet'
        replace: true
        scope:
            cluster: "=cluster"
        templateUrl: 'views/cluster.html'

        controller: 'ClusterController'

        link: ($scope, element, attrs, ctrl) ->
            console.log("current cluster id = ", $scope.cluster.id)
            $scope.cluster_elem = element[0]
            # FIXME : should no longer be required : get element width and height to place it correctly :   
            #   We watch the number of children to the "posts" node 
            #   when the ng-repeat loop within the posts has finished, 
            #   we can add the layer knowing then the cluster's height
            watch = $scope.$watch(()->
                return $(element[0]).find('.posts').children().length
            , ()-> 
                $scope.$evalAsync(()->
                    # Finally, directives are evaluated and templates are renderer here
                    children = $(element[0]).find('.posts').children()
                    ctrl.addHtmlLayer(element[0], $scope.cluster)
                )
            )      
            # ARTE player events binding
            ang_elem = angular.element(element)
            $timeout(() ->
                console.debug("POUETTTTTTTTTTTTTTTTTTT")
                console.debug(ang_elem)
                # Arte player
                $scope.arte_player_container = ang_elem.find('.video-container')[0]
                arte_player_container_object = $($scope.arte_player_container)
                console.log(" Arte video container = ", $scope.arte_player_container_object)
                iframe_sel = "#container_#{$scope.cluster.id} iframe"
                console.log(" Iframe selector = ", iframe_sel)

                $scope.arte_player_container_object = arte_player_container_object

                # listening to player events
                arte_player_container_object.on('arte_vp_player_config_ready', (element) ->
                    console.log(" >>> player config ready!! :: element ::", ang_elem)
                    console.debug(this)
                    console.log($(this.iframe_sel))
                    $scope.arte_player_container_object.find('iframe')[0].contentWindow.arte_vp.parameters.config.controls = false
                    $scope.arte_player_container_object.find('iframe')[0].contentWindow.arte_vp.parameters.config.primary = "html5"
                                            
                )
                arte_player_container_object.on('arte_vp_player_ready', ()->
                    console.log(" >>> player ready !!")
                    $scope.arte_player = $scope.arte_player_container_object.find('iframe')[0].contentWindow.arte_vp_player
                    $scope.sequence_loaded = true
                    $scope.sequence_playing = true
                )
            , 0)
    }
])

###
Directive to control player interactions
###
module.directive('playerContainer', [()->
    return{
        restrict: 'E'
        transclude: false
        replace: true
        #scope:
        template: '<div class="video-container"><div ng-transclude></div></div>'

        link: ($scope, element, attrs, ctrl) ->
            console.log(" player container directive loaded")

    }
])

###
Custom directive to triger a method passed as 
attribute parameter when a given element has completed loading, especially for iframes 
cf https://github.com/angular/angular.js/issues/2388
###
module.directive('myLoad', [()->                                      
    return {
        restrict : 'A'
        link: (scope, iElement, iAttrs, controller)->   
            scope.$watch(iAttrs, (value)=>                            
                iElement.bind('load', (evt)=>                                    
                    scope.$apply(iAttrs.myLoad)                                           
                )                                                                      
            )                                                                           
    }
])
