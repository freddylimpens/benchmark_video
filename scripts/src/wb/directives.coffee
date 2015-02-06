# -*- tab-width: 4 -*-
# HTML Layer
# FIXME : should be moved to separate file, but coffe compilation prevents from loading global object 
HtmlLayer = L.Class.extend({

initialize: (bounds, html_content, options) ->
        console.log("[ Layer ] Init HTML Layer")
        this._el = html_content
        this._bounds = L.latLngBounds(bounds)

onAdd: (map) ->
        #create a DOM element and put it into one of the map panes
        this._map = map;
        if (this._map.options.zoomAnimation && L.Browser.any3d) 
                console.log(" Adding zoom animated")
                L.DomUtil.addClass(this._el, 'leaflet-zoom-animated');
        # NormalZoomLevel (given in config) gives the zoom level at which scaling ratio is 1/1
        pixel_bounds = new L.Bounds(
                this._map.project(this._bounds.getNorthWest(), config.normalZoomLevel), 
                this._map.project(this._bounds.getSouthEast(), config.normalZoomLevel)
                )
        this._real_size = pixel_bounds.max.x - pixel_bounds.min.x
        console.log("[ Layer ] size = ", this._real_size)
        map.getPanes().overlayPane.appendChild(this._el)
        map.on('viewreset', this._reset, this)
        if (map.options.zoomAnimation && L.Browser.any3d)
                console.log(" Adding zoom anim callback")
                map.on('zoomanim', this._animateZoom, this)
        this._reset()
        console.log(" *** layer added *** ")

onRemove: (map) ->
        #remove layer's DOM elements and listeners
        map.getPanes().overlayPane.removeChild(this._el)
        map.off('viewreset', this._reset, this)

_animateZoom: (e)->
        #console.log(" animating zoom... ", e)          
        nw = this._bounds.getNorthWest()
        se = this._bounds.getSouthEast()
        topLeft = this._map._latLngToNewLayerPoint(nw, e.zoom, e.center)
        scale = this._map.getZoomScale(e.zoom)
        translateString = L.DomUtil.getTranslateString(topLeft) 
        this._el.style[L.DomUtil.TRANSFORM] = translateString + ' scale(' + scale + ') ';
        #console.log(" END animating zoom... ", e)          
        
_reset: (e) ->
        #console.log("[_reset] resetting layer, map ? ", e)
        html_layer = this._el
        # GEO bounds to PIXEL bounds
        topLeft = this._map.latLngToLayerPoint(this._bounds.getNorthWest())
        L.DomUtil.setPosition(html_layer, topLeft)
        # SCALING : computed after currently projected size 
        bounds = { value : new L.Bounds(
                this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
                this._map.latLngToLayerPoint(this._bounds.getSouthEast())
                )}
        currently_projected_size = bounds.value.max.x - bounds.value.min.x
        delete bounds.value
        # size = this._map.latLngToLayerPoint(this._bounds.getSouthEast())._subtract(topLeft);
        #console.log(" Projected size ? ", currently_projected_size)
        ts = this._real_size / currently_projected_size
        #console.log(" ts ? ", ts)
        transformScale = "scale("+(1/ts)+")"
        #console.log("[_reset] resetting layer, scale ? ", transformScale)
        # FIXME : conflict between global transform applied by leaflet to main node (html_layer) 
        #         and the local one we apply here, => apply transform on child node  
        elem_scaled = $(html_layer.childNodes[1])
        elem_scaled = $(elem_scaled)[0]
        #console.log(" [reset] element scaled : ", $(elem_scaled))
        # translateString = L.DomUtil.getTranslateString(topLeft) 
        # console.log("translate string AFTER ? ", translateString)
        # scaleString = L.DomUtil.getScaleString((1/ts), topLeft)
        # console.log("scale string AFTER ? ", scaleString )
        elem_scaled.style[L.DomUtil.TRANSFORM] = transformScale
        #html_layer.style[L.DomUtil.TRANSFORM] = translateString+" "+transformScale
        # $(elem_scaled).css({
        #                 '-webkit-transform': transformScale
        #                 '-moz-transform': transformScale
        #                 '-o-transform': transformScale
        #                 'transform': transformScale
        #             })
        return true
})

###################################

module = angular.module("leaflet-directive", [])

class LeafletController
        constructor: (@$scope, @$rootScope, @$timeout, @MapService, @$q) ->
                @$rootScope.incrementAsset = this.incrementAsset
                @$rootScope.assetIndex = 0 
                @$rootScope.mapLoaded = false
                @$scope.numberOfClustersLoaded = 0
                @$rootScope.dragging = false
                # Auto/Manuel mode vars
                @$rootScope.autoPlayerMode = config.autoPlayerMode # default is autoPlayer mode
                @$scope.playlistIndex = -1
                @$scope.currentSequenceBeingRead = config.playlist_cluster_order[0] # id of cluster to read
                @$rootScope.overlayPlayerOn = false
                @$rootScope.playPrevious = this.playPrevious
                # Set focus zoom level
                @$scope.setFocusZoomLevel = this.setFocusZoomLevel
                @$scope.setFocusZoomLevel()
                # Callbacks
                @$scope.$on('intro_exited', (event, data)=>
                        this.bindFancyBox()
                        if @$rootScope.autoPlayerMode
                                this.moveAndPlayNextSequence()
                    )
                # Playing sequence callback
                @$scope.$on('focus_on_sequence', (event, seq_id)=>
                        console.log(" [ leaflet controller ] playing seq ", seq_id)
                        # focus on sequence only if autoplayer mode disabled and not dragging
                        if !@$rootScope.autoPlayerMode && !@$rootScope.dragging
                                this.setFocusOnSequence(seq_id)
                    )

        isOnIpad:()=>
                """
                We check if not on iPad3 to deactivate touchZoom 
                """
                os = Detectizr.os
                if os.name == "ios"
                        console.log(" On iPad !")
                        return true
                else 
                        console.log("NOT On iPad !")
                        return false

        setFocusZoomLevel:()=>
                """
                Set zoom level and overlay player size when playing sequences according to screen resolution

                """
                console.log(" ++ screen res ", screen.availWidth)
                console.log(" window res ", window.innerWidth)
                try
                        @$scope.focusZoomLevel = switch
                                when ( @$scope.screenWidth > 1420 && @$scope.screenWidth < 2820) then 5
                                when ( @$scope.screenWidth > 2820) then 6
                                else 4
                        # Set overlay player size
                        # FIXME : get ratio value from config file
                        @$rootScope.playerWidth = window.innerWidth - 200
                        @$rootScope.playerHeight = parseInt((768 *  @$rootScope.playerWidth) / 1400)
                catch e
                        # Default value if something goes wrong
                        @$scope.focusZoomLevel = 5
                        @$rootScope.playerWidth = 1200
                        @$rootScope.playerHeight = 662
                @$rootScope.playerMarginLeft = -parseInt(@$rootScope.playerWidth / 2)
                @$rootScope.playerMarginTop = -parseInt(@$rootScope.playerHeight / 2)
                console.log(" playerWidth= "+@$rootScope.playerWidth+" playerHeight= "+@$rootScope.playerHeight)
                
        incrementAsset: ()=>
                """
                Used to roll around the subdomains for downloading assets
                """
                if @$rootScope.assetIndex < 4
                        @$rootScope.assetIndex++
                else if @$rootScope.assetIndex == 4
                        @$rootScope.assetIndex = 0

        setDragging: (bool)=>
                """
                used to avoid trigerring single click when dragging an element
                """
                @$rootScope.dragging = bool

        addUniqueHtmlLayer:(element)=>
                console.log(" *** ADDING UNIQUE LAYER *** ")
                # get element in directive template
                element = $(element).find('.themes')[0]
                # elem_height = $(element).height() 
                # elem_width = $(element).width()
                nE_x = config.globalWidth
                nE_y = 0
                sW_x = 0 
                sW_y = config.globalHeight
                # We use normal zoom level from config instead of map max zoom    
                southWest = @$scope.map.unproject([sW_x, sW_y], config.normalZoomLevel);
                northEast = @$scope.map.unproject([nE_x, nE_y], config.normalZoomLevel);
                layer_bounds = new L.LatLngBounds(southWest, northEast)
                aLayer = new HtmlLayer(layer_bounds, element)
                @$scope.map.addLayer(aLayer)
                southWest_max = @$scope.map.unproject([sW_x, sW_y+5000], config.normalZoomLevel);
                northEast_max = @$scope.map.unproject([nE_x+5000, nE_y], config.normalZoomLevel);
                layer_bounds_max = new L.LatLngBounds(southWest_max, northEast_max)
                @$scope.map.setMaxBounds(layer_bounds)

        oneMoreClusterLoaded: ()=>
                """
                Count number of cluster loaded and trigger exit intro when last has loaded
                """
                @$scope.numberOfClustersLoaded++
                console.log("[Cluster controller] one More loaded = ")
                if @$scope.numberOfClustersLoaded == Object.keys(@MapService.clusters).length
                        #this.exitIntro()
                        @$rootScope.mapLoaded = true


        getSequenceBounds: (cluster_id)=>
                console.log("[ leaflet controller ] Getting bounds for sequence ", cluster_id)
                seq_dom_object = angular.element('article#'+cluster_id)
                seq_north_east = @$scope.map.unproject(
                    [(@MapService.clusters[cluster_id].left+seq_dom_object.width()), @MapService.clusters[cluster_id].top],
                    config.normalZoomLevel)
                seq_bottom_left = [(@MapService.clusters[cluster_id].left), (@MapService.clusters[cluster_id].top + seq_dom_object.height())]
                seq_south_west = @$scope.map.unproject(seq_bottom_left, config.normalZoomLevel)
                seq_bounds = new L.LatLngBounds([seq_north_east, seq_south_west])
                return seq_bounds

        setFocusOnSequence: (cluster_id)=>
                console.log("[ leaflet controller ] Moving to sequence id =? ", cluster_id)
                seq_bounds = this.getSequenceBounds(cluster_id)
                @$timeout(()=>
                        @$scope.map.setView(seq_bounds.getCenter(), @$scope.focusZoomLevel, {animate:true, duration: 0.5})
                ,500)
                #console.log("[ leaflet controller ] moved to sequence")
                #@$scope.map.fitBounds(seq_bounds, {maxZoom:5})

        setIndexManually:(cluster_id)=>
                """
                When a sequence is playing check that index on playlist matches played sequence
                """
                @$scope.playlistIndex = config.playlist_cluster_order.indexOf(cluster_id)
                console.log("[setIndexManually] Set playlist index to  ",  @$scope.playlistIndex )

        playPrevious:()=>
                console.log("[ leaflet controller ] playing previous seq ", @$scope.playlistIndex)
                
                seq_id = config.playlist_cluster_order[@$scope.playlistIndex-1]
                @$rootScope.$broadcast('move_and_play', seq_id)

        moveAndPlayNextSequence: ()=>
                """
                If autoPlayerMode toggled, zoom out and set focus on next sequence to play in the list
                """
                if !@$rootScope.autoPlayerMode
                        return false
                console.log("[ leaflet controller ] Moving and play : index = ", @$scope.playlistIndex)
                # case end of playlist = loop again
                if @$scope.playlistIndex == config.playlist_cluster_order.length-1
                        @$scope.playlistIndex = 0   
                else
                        @$scope.playlistIndex++
                sequence_id = config.playlist_cluster_order[@$scope.playlistIndex]
                # 1 Unzoom
                if @$scope.playlistIndex != 0 
                        @$scope.map.setZoom(3)
                # 2 Pan slowly
                seq_bounds = this.getSequenceBounds(sequence_id)
                @$timeout(()=>        
                        @$scope.map.panTo(seq_bounds.getCenter(), {animate:true, duration:3.0})
                        @$scope.map.once('moveend',()=>
                                console.log(" ENd of pananimation ?")
                                @$scope.map.setZoom(@$scope.focusZoomLevel)
                                @$timeout(()=>
                                            console.log("[ leaflet controller ]  sending signal move_and_play ")
                                            @$rootScope.$broadcast('move_and_play', sequence_id)
                                ,500)
                        )
                ,500)
                #### Old method (in case above is not that greater):
                # @$scope.map.panTo(seq_bounds.getCenter(), {animate:true, duration:3.0})
                # 3 Zoom on seq and send play signal
                # @$timeout(()=>
                #             @$scope.map.setZoom(@$scope.focusZoomLevel)
                # ,4000)
                # @$timeout(()=>
                #             console.log("[ leaflet controller ]  sending signal move_and_play ")
                #             #@$scope.map.setZoom(@$scope.focusZoomLevel)
                #             @$rootScope.$broadcast('move_and_play', sequence_id)
                # ,4500)

        toggleAutoPlayerMode: ()=>
                if @$rootScope.autoPlayerMode
                        @$rootScope.autoPlayerMode = false
                        console.log(" ==== Exit Auto player mode ==== ")

        bindFancyBox: ()=>
                console.log("[Leaflet controller] Fancy box init :")
                @$scope.map.addEventListener("click", (e)->
                        console.log(" clicked event obj ", e)
                        elem = e.originalEvent.target
                        e.originalEvent.stopPropagation()
                        main_post_elem = $(elem).parents('.post')[0]
                        if !$(main_post_elem).hasClass('clickable')
                                return false
                        fb_elem = $(elem).parents('.fancybox')[0]
                        console.log(" Element to fancybox = ", fb_elem)
                        gallery_index = 0
                        # For images
                        if $(fb_elem).hasClass('image') # NOTE : to create galleries we d need to recreate it from start
                                post_elem = $(fb_elem).parents('div.images')
                                console.log(" post elem = ", post_elem)
                                images = $(post_elem).find("div.image")
                                gallery_index = $(images).index(fb_elem)
                                fb_elem = images
                        # For text
                        else if $(fb_elem).hasClass('text')
                                fb_elem = $(fb_elem).find('section.post')[0]
                        # For video
                        else if $(fb_elem).hasClass('video')
                                console.log(" video type")
                                fb_elem = {href:$(fb_elem).attr('href'), type:'iframe'}
                        console.log("[Leaflet controller] clucked on fancybox Element  = ", fb_elem)
                        $.fancybox(fb_elem,{
                                index: gallery_index,
                                beforeShow : ()->
                                       this.title =  $(this.element).data("caption");
                                padding : 0,
                                maxWidth : '90%',
                                maxHeight : '90%',
                                fitToView : false,
                                width : '80%',
                                height : '80%',
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
            
            

module.controller("LeafletController", ['$scope', '$rootScope', '$timeout', 'MapService', '$q', LeafletController])

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
                        #L.Browser.any3d = L.Browser.gecko3d = false
                        $scope.map = new L.Map($el,
                                zoomControl: true
                                zoomAnimation: true
                                fadeAnimation: false
                                zoomAnimationThreshold: 1
                                touchZoom: !(ctrl.isOnIpad())
                                doubleClickZoom: false
                                minZoom: 1
                                maxZoom: 6
                                crs: L.CRS.Simple
                        )
                        $scope.dragging  = false
                        console.log(" [Leaflet directive] Map created")
                        # Center Change callback
                        $scope.$watch("center", (center, oldValue) ->
                                console.log("map center changed")
                                lat_lng_center = $scope.map.unproject([center.left, center.top], $scope.map.getMaxZoom())
                                console.log(" latlng center? ", lat_lng_center)
                                $scope.map.setView([lat_lng_center.lat, lat_lng_center.lng], 3)
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
                        console.log("[HtmlLayer directive]")
                        $timeout(()->
                                ctrl.addUniqueHtmlLayer(element[0])
                        ,100)
        }
])

class ClusterController
        constructor: (@$scope, @$rootScope, @overlayPlayerService) ->
                #console.log(" ++ Cluster Controler ++ current cluster id = ", @$scope.cluster.id)
                @$scope.sequence_loaded = false
                @$scope.sequence_focused = false
                @$scope.sequence_being_loaded = false
                @$scope.sequence_playing = false
                @$scope.areWeOnFirefox = this.areWeOnFirefox
                @$scope.overlayPlayer = this.overlayPlayer
                @$scope.resetArtePlayer = this.resetArtePlayer
                @$scope.closeOverlayPlayer = this.closeOverlayPlayer
                @$scope.loadPlayPauseSequence = this.loadPlayPauseSequence

                # AutoPlayer mode : Move and play sequence callback
                @$scope.$on('move_and_play', (event, seq_id)=>
                        console.log("[ cluster controller ] Move and play received : seq_id = "+seq_id+" own seq id = "+@$scope.cluster.id)
                        # console.log("[ cluster controller ] cluster id = "+@$scope.cluster.id+" player mode ?"+@$rootScope.autoPlayerMode)
                        if seq_id == @$scope.cluster.id && @$rootScope.autoPlayerMode
                               console.log("  [ cluster controller ] I'm gonna play my sequence ! = ", @$scope.cluster.id)
                               this.loadPlayPauseSequence() 
                               @$scope.sequence_focused = true
                    )
                # General case : Upon reception of playing  signal:
                @$scope.$on('playing_sequence', (event, seq_id)=>
                        console.log("[ cluster controller ] playing_sequence = ", seq_id)
                        if seq_id != @$scope.cluster.id && @$scope.sequence_loaded == true
                                console.log("[ cluster controller ] Stop all when play one != ")
                                this.resetArtePlayer()
                    )
                
                @$scope.$on('close_overlay', (event, cluster_id)=>
                        console.log("closing overlay for cluster id : ", cluster_id)
                        if cluster_id == @$scope.cluster.id
                                this.closeOverlayPlayer()
                    )

        areWeOnFirefox:()=>
                if @$rootScope.onFirefox
                        return true
                else
                        return false


        overlayPlayer:()=>
                """
                When on Firefox, move the player iframe to an overlay (see map.html)
                """
                #if @$rootScope.onFirefox
                #console.log("playing overlay")
                @overlayPlayerService.overlayPlayerOn = true
                cont = angular.element('#video-embed-container')
                @$scope.original_sequence_container = @$scope.arte_player_container_object.parent()[0]
                @$scope.arte_player_container_object.detach()
                cont.append(@$scope.arte_player_container_object)
                @overlayPlayerService.setClusterOverlaidId(@$scope.cluster.id)
                console.log("player overlaid", @overlayPlayerService.clusterOverlaidId)

        closeOverlayPlayer:()=>
                """
                Close overlay and restore player 
                """
                @overlayPlayerService.overlayPlayerOn = false
                this.resetArtePlayer()
                @$scope.arte_player_container_object.detach()
                # reappend to original place
                cont = $(@$scope.original_sequence_container)
                cont.append(@$scope.arte_player_container_object)
                console.log("[ClusterController.closeOverlayPlayer] closed overlayPlayer")

        resetArtePlayer:()=>
                if  @$scope.sequence_being_loaded
                        angular.element('.arte_vp_jwplayer_iframe').remove()
                        @$scope.sequence_being_loaded = false
                        console.log("[ ClusterController.resetArtePlayer] Arte player destroyed and reset")

                else if @$scope.sequence_loaded
                        #FIXME: this is breaking on IE : @$scope.iframe.remove()
                        @$scope.sequence_being_loaded = false
                        @$scope.jwplayer.stop()
                        @$scope.sequence_playing = false
                        @$scope.jwplayer.destroyPlayer()
                        angular.element('.arte_vp_jwplayer_iframe').remove()
                        @$scope.jwplayer = {}
                        @$scope.sequence_loaded = false
                        console.log("[ ClusterController.resetArtePlayer] Arte player destroyed and reset")

        loadPlayPauseSequence: ()=>
                """
                Load / Play / Pause a video sequence 
                """
                #console.log(" Dragging ?? ", @$scope.$parent.dragging)
                if @$rootScope.dragging
                        console.log(" >>>>> Dont- play, I'm dragged !")
                        return false
                console.log("[ ClusterController.Player ] loading/playing sequence for cluster id = "+@$scope.cluster.id+" name = "+@$scope.cluster.data.name)
                @$rootScope.$broadcast('playing_sequence', @$scope.cluster.id)
                console.log("[ ClusterController.Player ] ALready loaded ?? ", @$scope.sequence_loaded)
                # Loading sequence with arte iFramizator (from arte main.js)
                if  !@$scope.sequence_loaded && !@$scope.sequence_being_loaded
                        this.overlayPlayer()
                        arte_vp_iframizator(@$scope.arte_player_container_object)
                        @$scope.sequence_being_loaded = true
                        console.log("[ClusterController.Player] after append overlay player")
                
                # FIXME ? below is no longer used since we no longer have tpt layer over iframe    
                else if @$scope.sequence_loaded && !@$scope.sequence_playing
                        @$scope.jwplayer.play()

                else if @$scope.sequence_loaded && @$scope.sequence_playing
                        @$scope.jwplayer.pause()
                        
module.controller("ClusterController", ['$scope', '$rootScope', 'overlayPlayerService', ClusterController])

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
                templateUrl: 'views/cluster.html'

                controller: 'ClusterController'

                link: ($scope, element, attrs, ctrl) ->
                    ang_elem = angular.element(element)
                    $timeout(() ->
                            # Check if loading last element in loop
                            ctrl.oneMoreClusterLoaded()
                            # Arte player
                            $scope.arte_player_container = ang_elem.find('.video-container')[0]
                            #DELETE ME $scope.arte_player_fancybox_container = ang_elem.find('.video-container-fancybox')[0]
                            $scope.arte_player_container_object = $($scope.arte_player_container)
                            iframe_sel = "#container_#{$scope.cluster.id} iframe"

                            # listening to player events
                            $scope.arte_player_container_object.on('arte_vp_player_config_ready', (event, arte_vp, window) ->
                                    console.log("[ArtePlayer]>>> player config ready!!")
                                    $scope.iframe = angular.element.find(iframe_sel)[0]
                                    arte_vp.opts.data.tab_config[arte_vp.opts.config_name].primary = "html5"
                                    $($scope.iframe).removeAttr('allowfullscreen')
                                    console.log("[ArtePlayer] After config")
                            )
                            $scope.arte_player_container_object.on('arte_vp_player_created', (event, arte_vp, window) ->
                                    #console.log("[ArtePlayer] player created (before getting player object)")
                                    $scope.jwplayer = arte_vp.getJwPlayer()
                                    $scope.jwplayer.setFullscreen(false)
                                    #$scope.jwplayer.setControls(false)
                                    console.log("[ArtePlayer] player created ")
                            )
                            $scope.arte_player_container_object.on('arte_vp_player_ready', ()->
                                    console.log("[ArtePlayer] player ready / Rendering mode : ", $scope.jwplayer.getRenderingMode())
                                    $scope.sequence_loaded = true
                                    $scope.sequence_being_loaded = false
                                    #console.log("[ArtePlayer] binding events to player ")
                                    $scope.jwplayer.onPlay(()->
                                            console.log("[ArtePlayer] player playing")
                                            $scope.sequence_playing = true
                                            ctrl.setFocusOnSequence($scope.cluster.id)
                                            ctrl.setIndexManually($scope.cluster.id)
                                    )
                                    $scope.jwplayer.onPause(()->
                                            console.log("[ArtePlayer] player paused")
                                            $scope.sequence_playing = false
                                    )
                                    $scope.jwplayer.onBeforeComplete(()->
                                            console.log("[ArtePlayer]  player completed playing")
                                            $scope.closeOverlayPlayer()
                                            #$scope.resetArtePlayer()
                                            #$scope.jwplayer.seek(0)
                                            ctrl.moveAndPlayNextSequence()
                                            console.log("[ArtePlayer]  player removed / moving on")
                                    )
                                    # remove fullscreen button except on Firefox
                                    if !$scope.areWeOnFirefox()
                                            try 
                                                    el = $scope.iframe.contentWindow.$.find('.jwfullscreen')[0]
                                                    $(el).remove()
                                                    console.log("after removing FS ? el = ", $(el))
                                            catch error
                                                    console.log(" Error when removing fs button")
                                            finally
                                                    console.log(" removed fullscreen button")
                            )
                    , 0)
        }
])
