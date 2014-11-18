# -*- tab-width: 4 -*-
# HTML Layer
# FIXME : should be moved to separate file, but coffe compilation prevents from loading global object 
HtmlLayer = L.Class.extend({

options:
        opacity: 1
        alt: ''
        zoomAnimation: false

initialize: (bounds, html_content, options) ->
        #save position of the layer or any options from the constructor
        this._el = html_content
        console.log("[ Layer ] Init HTML Layer", html_content)
        this._bounds = L.latLngBounds(bounds)
        console.log("[ Layer ] bounds ? = ", this._bounds)
        # FIXME : deal with options ??
        #L.setOptions(this, options);

onAdd: (map) ->
        #create a DOM element and put it into one of the map panes
        this._map = map;
        L.DomUtil.addClass(this._el, 'leaflet-zoom-animated')
        pixel_bounds = new L.Bounds(
                this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
                this._map.latLngToLayerPoint(this._bounds.getSouthEast())
                )
        console.log("[ Layer ] original bounds ? = ", pixel_bounds)
        this._real_size = pixel_bounds.max.x - pixel_bounds.min.x
        console.log("[ Layer ] size ? = ", this._real_size)
        map.getPanes().overlayPane.appendChild(this._el)
        #add a viewreset event listener for updating layer's position, do the latter
        map.on('viewreset', this._reset, this)
        map.on('zoomanim', this._animateZoom, this)
        this._reset()
        console.log(" *** layer added ***")

onRemove: (map) ->
        #remove layer's DOM elements and listeners
        map.getPanes().overlayPane.removeChild(this._el)
        map.off('viewreset', this._reset, this)

_animateZoom: (e)->
        console.log(" animating zoom... ", e)          
        # topLeft = this._map._latLngToNewLayerPoint(this._bounds.getNorthWest(), e.zoom, e.center)
        nw = this._bounds.getNorthWest()
        se = this._bounds.getSouthEast()
        topLeft = this._map._latLngToNewLayerPoint(nw, e.zoom, e.center)
        bottomRight = this._map._latLngToNewLayerPoint(se, e.zoom, e.center)
        new_bounds = new L.Bounds(topLeft, bottomRight)
        scale = this._map.getZoomScale(e.zoom)
        size = this._map._latLngToNewLayerPoint(se, e.zoom, e.center)._subtract(topLeft)
        #origin = topLeft._add(size._multiplyBy((1 / 2) * (1 - 1 / scale)))
        origin = new_bounds.getCenter()
        # !FIXME! : check that above version works on all platform, if not try following :
        # transformString = L.DomUtil.getTranslateString(new_bounds.getCenter()) + ' scale(' + e.scale + ') '
        # $(this._el).css({ 
        #                 '-webkit-transform': transformString
        #                 '-moz-transform': transformString
        #                 '-o-transform': transformString
        #                 'transform': transformString
        #             })                        
        # translateString = L.DomUtil.getTranslateString(new_bounds.getCenter()) 
        translateString = L.DomUtil.getTranslateString(origin) 
        this._el.style[L.DomUtil.TRANSFORM] = translateString + ' scale(' + scale + ') ';
        
                                                                                                                                   

_reset: () ->
        console.log("[_reset] resetting layer")
        # POSITION : update layer's position with new bounds
        html_layer = this._el
        # GEO bounds to PIXEL bounds
        bounds = new L.Bounds(
                this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
                this._map.latLngToLayerPoint(this._bounds.getSouthEast())
                )
        console.log("[reset] bounds ? = ", bounds)
        topLeft = this._map.latLngToLayerPoint(this._bounds.getNorthWest())
        console.log("[reset] top left ? = ", topLeft)
        L.DomUtil.setPosition(html_layer, bounds.getCenter())
        #L.DomUtil.setPosition(html_layer, topLeft)
        # SCALING : computed after currently projected size 
        currently_projected_size = bounds.max.x - bounds.min.x
        ts = this._real_size / currently_projected_size
        transformScale = "scale("+(1/ts)+")"
        console.log(" [reset] transform scale string : ", transformScale)
        # FIXME : conflict between global transform applied by leaflet to main node (html_layer) 
        # and the local one we apply here, => apply transform on child node  
        #elem_scaled = $(html_layer)[0]
        elem_scaled = $(html_layer.childNodes[1])
        elem_scaled = $(elem_scaled)[0]
        console.log(" [reset] element scaled : ", $(elem_scaled))
        $(elem_scaled).css({
                        '-webkit-transform': transformScale
                        '-moz-transform': transformScale
                        '-o-transform': transformScale
                        'transform': transformScale
                    })
})

###################################

module = angular.module("leaflet-directive", [])

class LeafletController
        constructor: (@$scope, @$rootScope, @$timeout, @MapService) ->
                @$scope.html_layer_instances = [] # not used so far
                @$scope.clusters = @MapService.clusters
                @$scope.numberOfClustersLoaded = 0
                @$scope.clusters_layer_bounds = {}
                @$rootScope.dragging = false
                # Auto/Manuel mode vars
                @$rootScope.autoPlayerMode = config.autoPlayerMode # default is autoPlayer mode
                @$scope.manualNavMode = false # Not used
                @$scope.playlistIndex = -1
                @$scope.currentSequenceBeingRead = config.playlist_cluster_order[0] # id of cluster to read
                # Callbacks
                @$scope.$on('intro_exited', (event, data)=>
                        this.bindFancyBox()
                        if @$rootScope.autoPlayerMode
                                this.moveAndPlayNextSequence()
                    )
                # Playing sequence callback
                @$scope.$on('playing_sequence', (event, seq_id)=>
                        console.log(" [ leaflet controller ] playing seq ", seq_id)
                        # focus on sequence only if autoplayer mode disabled and not dragging
                        if !@$rootScope.autoPlayerMode && !@$rootScope.dragging
                                this.setFocusOnSequence(seq_id)
                    )

        setDragging: (bool)=>
                @$rootScope.dragging = bool

        addUniqueHtmlLayer:(element)=>
                # global layer coordinates
                element = $(element).find('.themes')[0]
                elem_height = $(element).height()
                elem_width = $(element).width()
                console.log(" *** ADDING UNIQUE LAYER *** h = "+elem_height+" w = "+elem_width)
                nE_x = elem_width
                nE_y = 0
                sW_x = 0 
                sW_y = elem_height
                console.log(" layer coords SW :", [sW_x, sW_y])
                console.log(" layer coords NE :", [nE_x, nE_y])
                southWest = @$scope.map.unproject([sW_x, sW_y], @$scope.map.getMaxZoom());
                northEast = @$scope.map.unproject([nE_x, nE_y], @$scope.map.getMaxZoom());
                layer_bounds = new L.LatLngBounds(southWest, northEast)
                console.log(" layer bounds ", layer_bounds)
                aLayer = new HtmlLayer(layer_bounds, element)
                @$scope.map.addLayer(aLayer)

        # Add HtmlContent Layer
        # REMOVE-ME : OBSOLETE
        addHtmlLayer:(element, cluster) =>
                # FIXME : there should not be any template-dependent id, class or anything here
                elem_height = $(element).find(".sequence").height()
                elem_width = $(element).find(".sequence").width()
                console.log(" *** ADDING LAYER *** h = "+elem_height+" w = "+elem_width)
                #calculate the edges of the image, in coordinate space        
                nE_x = cluster.left + elem_width
                nE_y = cluster.top
                sW_x = cluster.left 
                sW_y = cluster.top + elem_height 
                southWest = @$scope.map.unproject([sW_x, sW_y], @$scope.map.getMaxZoom());
                northEast = @$scope.map.unproject([nE_x, nE_y], @$scope.map.getMaxZoom());
                layer_bounds = new L.LatLngBounds(southWest, northEast)
                @$scope.clusters_layer_bounds[cluster.id] = layer_bounds
                aLayer = new HtmlLayer(layer_bounds, element)
                @$scope.map.addLayer(aLayer)

        oneMoreClusterLoaded: ()=>
                """
                Count number of cluster loaded and trigger exit intro when last has loaded
                """
                @$scope.numberOfClustersLoaded++
                console.log("[Cluster controller] one More loaded = ", @$scope.numberOfClustersLoaded)
                if @$scope.numberOfClustersLoaded == Object.keys(@$scope.clusters).length
                        this.exitIntro()

        exitIntro: ()=>
                console.log("[Cluster controller] Exit intro !")
                intro_overlay = angular.element('.intro')
                intro_overlay.animate({
                            top:-intro_overlay.height()
                        }, 
                        {   
                            duration: 1200,
                            easing: 'easeInOutExpo',
                            complete: ()=>
                                    intro_overlay.hide()
                                    @$rootScope.$broadcast('intro_exited')
                                    console.log("+++ intro exited ++++")
                        }
                )

        setFocusOnSequence: (sequence_id)=>
                console.log("[ leaflet controller ] Moving to sequence id =? ", sequence_id)
                #>>> Retrieve seq coordinates
                seq_cluster = @$scope.clusters[sequence_id]
                seq_dom_object = angular.element('#sequence_'+seq_cluster.data.id)
                seq_coord = @$scope.map.unproject([seq_cluster.left, seq_cluster.top], @$scope.map.getMaxZoom())
                seq_bounds = @$scope.clusters_layer_bounds[seq_cluster.id]
                seq_south_east = seq_bounds.getSouthEast()
                @$scope.map.setView([seq_south_east.lat, seq_south_east.lng], 5, 
                            {reset:false, pan:{ animate : true, duration : 2,  easeLinearity: 0.5, noMoveStart:false}, zoom:{animate:true}})
                console.log("[ leaflet controller ] moved to sequence")

        moveAndPlayNextSequence: ()=>
                console.log("[ leaflet controller ] Moving and play : index = ", @$scope.playlistIndex)
                # case end of playlist = loop again
                if @$scope.playlistIndex == config.playlist_cluster_order.length-1
                        @$scope.playlistIndex = 0
                else
                        @$scope.playlistIndex++
                sequence_id = config.playlist_cluster_order[@$scope.playlistIndex]
                # 1. unzoom to zoom level 2 or 3
                @$scope.map.setZoom(2, {animate:true})
                # 2. focus to sequence
                @$timeout(()=>
                        this.setFocusOnSequence(sequence_id)  
                ,2000)
                # Broadcast signal
                console.log(" [ Leaflet controller ]  sending signal move_and_play ")
                @$timeout(()=>
                            @$rootScope.$broadcast('move_and_play', sequence_id)
                ,500)

        bindFancyBox: ()=>
                console.log("[Leaflet controller] Fancy box init :")
                @$scope.map.addEventListener("click", (e)->
                        console.log(" clicked event obj ", e)
                        elem = e.originalEvent.srcElement
                        console.log(" Element to fancybox = ", elem)
                        fb_elem = $(elem).parents('.fancybox')[0]
                        gallery_index = 0
                        # For images
                        console.log(" is fancy box image class ", $(fb_elem).hasClass('fancyboximage'))
                        if $(fb_elem).hasClass('fancyboximage') # NOTE : to create galleries we d need to recreate it from start
                                post_elem = $(fb_elem).parents('div.images')
                                console.log(" post elem = ", post_elem)
                                images = $(post_elem).find("button.fancyboximage")
                                gallery_index = $(images).index(fb_elem)
                                fb_elem = images

                        # For text
                        console.log(" is fancy box text class ", $(fb_elem).hasClass('fancyboxtext'))
                        if $(fb_elem).hasClass('fancyboxtext')
                                fb_elem = $(fb_elem).find('section.post')[0]
                        console.log(" fancybox Element  = ", fb_elem)
                        $.fancybox(fb_elem,{
                                index: gallery_index,
                                padding : 0,
                                maxWidth : 800,
                                maxHeight : 600,
                                fitToView : false,
                                width : '70%',
                                height : '90%',
                                autoSize : false,
                                closeClick : false,
                                openEffect : 'none',
                                closeEffect : 'none',
                                tpl: {
                                        next : '<a title="Next" class="fancybox-nav fancybox-next fancybox-wb-next" href="javascript:;"></a>',
                                        prev : '<a title="Previous" class="fancybox-nav fancybox-prev fancybox-wb-prev" href="javascript:;"></a>',
                                        closeBtn: '<a title="Close" class="fancybox-item fancybox-close fancybox-wb-close" href="javascript:;"></a>'
                                },
                                helpers : {
                                        overlay : {
                                            css : {
                                                'background' : 'rgba(255, 255, 255, 0.95)'
                                            }
                                        }
                                },
                                ajax : { 
                                        dataType : 'html', 
                                        headers : false
                                }
                        })
                )
            
            

module.controller("LeafletController", ['$scope', '$rootScope', '$timeout', 'MapService', LeafletController])

module.directive("leaflet", ["$http", "$log", "$location", "$timeout", ($http, $log, $location, $timeout) ->
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
                                touchZoom: true
                                doubleClickZoom: false
                                minZoom: 0
                                maxZoom: 5
                                crs: L.CRS.Simple
                        )
                        $scope.dragging  = false
                        console.log(" [Leaflet directive] Map created")
                        # Center Change callback
                        $scope.$watch("center", (center, oldValue) ->
                                console.debug("map center changed")
                                lat_lng_center = $scope.map.unproject([center.left, center.top], $scope.map.getMaxZoom())
                                $scope.map.setView([lat_lng_center.lat, lat_lng_center.lng], center.zoom)
                        ,true)
                        # Callback for drag events to prevent unwanted click events   
                        $scope.map.on('dragstart', ()->
                                console.log(' >> dragging start')
                                ctrl.setDragging(true)    
                        )
                        $scope.map.on('dragend', (e)->
                                console.log(' >> dragging ended')
                                $timeout(()->
                                        ctrl.setDragging(false)  
                                ,500)  
                        )
                }
])

module.directive("htmlLayer", ["$timeout", ($timeout)->
        return {
                restrict: 'E'
                require: '^leaflet'
                replace: true
                transclude:true
                scope: {}
                template: '<div class="angular-leaflet-html-layer"><div ng-transclude ></div></div>'

                link:($scope, element, attrs, ctrl) ->
                        console.log("[HtmlLayer directive]", element)
                        $timeout(()->
                                ctrl.addUniqueHtmlLayer(element[0])
                        ,100)
        }
])

class ClusterController
        constructor: (@$scope, @$rootScope) ->
                console.log(" ++ Cluster Controler ++ current cluster id = ", @$scope.cluster.id)
                @$scope.sequence_loaded = false
                @$scope.sequence_being_loaded = false
                @$scope.sequence_playing = false
                @$scope.loadPlayPauseSequence = this.loadPlayPauseSequence

                # AutoPlayler mode : Move and play sequence callback
                @$scope.$on('move_and_play', (event, seq_id)=>
                        console.log(" [ cluster controller ] Move and play : data= ", seq_id)
                        #console.log(" cluster id = "+@$scope.cluster.id+" player mode ?"+@$rootScope.autoPlayerMode)
                        if seq_id == @$scope.cluster.id && @$rootScope.autoPlayerMode
                               console.log("  [ cluster controller ] I'm gonna play my sequence ! = ", @$scope.cluster.id)
                               this.loadPlayPauseSequence() 
                    )
                # General case : Upon reception of playing  signal:
                @$scope.$on('playing_sequence', (event, seq_id)=>
                        console.log(" [ cluster controller ] playing_sequence = ", seq_id)
                        if seq_id != @$scope.cluster.id && @$scope.sequence_playing == true
                                console.log(" [ cluster controller ] Pause all when play one != ")
                                @$scope.jwplayer.pause()
                    )

        loadPlayPauseSequence: ()=>
                """
                Load / Play / Pause a video sequence 
                """
                console.log(" Dragging ?? ", @$scope.$parent.dragging)
                if @$rootScope.dragging
                        console.log(" >>>>> Dont- play, I'm dragged !")
                        return false
                console.log("[ ClusterController.Player ] loading/playing sequence for cluster id = ", @$scope.cluster.id )
                @$rootScope.$broadcast('playing_sequence', @$scope.cluster.id)
                console.log("[ ClusterController.Player ] ALready loaded ?? ", @$scope.sequence_loaded)
                # Loading sequence with arte iFramizator (from arte main.js)
                if  !@$scope.sequence_loaded && !@$scope.sequence_being_loaded
                        console.log(" Iframizator !!", @$scope.arte_player_container_object)
                        arte_vp_iframizator(@$scope.arte_player_container_object)
                        @$scope.sequence_being_loaded = true
                    
                else if @$scope.sequence_loaded && !@$scope.sequence_playing
                        @$scope.jwplayer.play()

                else if @$scope.sequence_loaded && @$scope.sequence_playing
                        @$scope.jwplayer.pause()
                        # Toggle AutoPlayer mode if active
                        if @$rootScope.autoPlayerMode
                                console.log("[ ClusterController.Player ] Exit AutoPlayer mode !!")
                                @$rootScope.autoPlayerMode = false

module.controller("ClusterController", ['$scope', '$rootScope', ClusterController])

###
Directive to control loading and binding for each cluster linked to a given theme
###
module.directive("htmlCluster", ["$timeout", "$rootScope", ($timeout, $rootScope) ->
        return {
                restrict: 'E'
                require: '^leaflet'
                replace: true
                scope:
                        cluster: "=cluster"
                        loopindex: "@"
                        lastinloop: "@"
                templateUrl: 'views/cluster.html'

                controller: 'ClusterController'

                link: ($scope, element, attrs, ctrl, $rootScope) ->
                    console.log("current cluster id = ", $scope.cluster.id)
                    $scope.cluster_elem = element[0]
                    #ctrl.addHtmlLayer(element[0], $scope.cluster)
                    
                    # ARTE player events binding
                    ang_elem = angular.element(element)
                    $timeout(() ->
                            # Check if loading last element in loop
                            console.log("[Cluster Directive] index in ng-repeat loop ? ", $scope.loopindex)
                            ctrl.oneMoreClusterLoaded()
                            # Arte player
                            $scope.arte_player_container = ang_elem.find('.video-container')[0]
                            $scope.arte_player_container_object = $($scope.arte_player_container)
                            console.log("[Cluster Directive] Arte video container = ", $scope.arte_player_container_object)
                            iframe_sel = "#container_#{$scope.cluster.id} iframe"

                            # listening to player events
                            $scope.arte_player_container_object.on('arte_vp_player_config_ready', (element) ->
                                    console.log(" [ArtePlayer]>>> player config ready!!", element)
                                    $scope.iframe = ang_elem.find(iframe_sel)[0]
                                    console.log(" [ArtePlayer] iframe = ", $scope.iframe)
                                    $scope.iframe.contentWindow.arte_vp.player_config.controls = false
                                    $scope.iframe.contentWindow.arte_vp.parameters.config.primary = "html5"
                                    console.log(" [ArtePlayer] After config ; arte_vp object : ", $scope.iframe.contentWindow.arte_vp )
                            )
                            $scope.arte_player_container_object.on('arte_vp_player_created', (element) ->
                                    $scope.jwplayer = $scope.iframe.contentWindow.arte_vp.getJwPlayer()
                                    $scope.iframe.contentWindow.arte_vp.getJwPlayer().setControls(false)
                                    console.log("[ArtePlayer] player created / jwplayer instance : ", $scope.jwplayer )
                                    $scope.jwplayer.setFullScreen(true)
                                    console.log("[ArtePlayer] after set control")
                            )
                            $scope.arte_player_container_object.on('arte_vp_player_ready', ()->
                                    console.log("[ArtePlayer] player ready / Rendering mode : ", $scope.jwplayer.getRenderingMode())
                                    $scope.sequence_loaded = true
                                    $scope.sequence_being_loaded = false
                                    console.log("[ArtePlayer] binding events to player ")
                                    $scope.jwplayer.onPlay(()->
                                            console.log("[ArtePlayer] player playing")
                                            $scope.sequence_playing = true
                                    )
                                    $scope.jwplayer.onPause(()->
                                            console.log("[ArtePlayer] player paused")
                                            $scope.sequence_playing = false
                                    )
                                    $scope.jwplayer.onBeforeComplete(()->
                                            console.log("[ArtePlayer]  player completed playing")
                                            $scope.jwplayer.stop()
                                            $scope.sequence_playing = false
                                            $scope.jwplayer.seek(0)
                                            console.log("[ArtePlayer] player mode ?", $rootScope.autoPlayerMode)
                                            # If Autoplayer mode active =>> broadcast signal
                                            ctrl.moveAndPlayNextSequence()
                                            if $rootScope.autoPlayerMode
                                                    console.log("[ArtePlayer] move and play next seq")
                                    )
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

module.directive('myRepeatDirective', [()->
        return {
                restrict: 'A'
                link: (scope, element, attrs) ->
                        if (scope.$last)
                                console.log("im the last!")
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
