services = angular.module('wb.services', ['restangular'])

class MapService
        constructor: (@$compile, @Restangular, @$http, @$rootScope, @$timeout, @$window) ->
                console.log(" Building map service")
                # Center given in pixel coordinates
                @center =
                        top: 4000
                        left: 11000
                        zoom: 4

                @clusters = {}
                @pages = {}
                # Map loading vars
                @mapIsLoading = false
                @dataLoaded = false
                @$rootScope.mapLoaded = false
                # default lang is french
                @$rootScope.chosen_language = 'fr'
                @SupportMessage = ''
                @BrowserSupported = this.checkBrowserSupported()
                console.log(" *** Browser supported ? ***  ", @BrowserSupported)
                console.log(" *** Support Message ? ***  ", @SupportMessage)
                # get Browser
                @$rootScope.onFirefox = this.browserIsFirefox()
                console.log(" firefox ?? ", @$rootScope.onFirefox)
                @showCredits = false
                @showInfo = false
                # timeline list : 
                @$rootScope.timeline = [config.playlist_cluster_order.length]

        checkBrowserSupported:()=>
                # console.log("Browser ? ", userAgent)
                console.log("Browser name ? ", Detectizr.browser.name)
                bname =  Detectizr.browser.name
                console.log("Browser version (major) ? ", Detectizr.browser.major)
                bversion =  Detectizr.browser.major
                console.log("Device ? ", Detectizr.device)
                device = Detectizr.device
                if device.type not in  ['desktop', 'tablet']
                        @SupportMessage = 'device_unsupported'
                        return false
                # Device type supported: device.type =  'desktop', 'tablet' > discard others
                else if device.type == 'tablet'
                        # When tablet : support only device.model = 'ipad' + 'android'
                        if device.model == 'ipad'
                                # above which iOs version ?
                                return true
                        else if device.model == 'android'
                                # above which Android version ?
                                return true
                        else
                                @SupportMessage = 'device_unsupported'
                                return false
                # desktop supports : Safari >= 6, Chrome >= 39, IE >= 10, iOs/Safari >= Ipad2, Android/Chrome >= 
                else if device.type == 'desktop'
                        if bname == "firefox"
                                uptodate = if bversion >= 30 then true  else false
                        else if bname == "chrome"
                                uptodate = if bversion >= 32 then true  else false
                        else if bname == "safari"
                                uptodate = if bversion >= 6 then true  else false
                        else if bname == "ie"
                                uptodate = if bversion >= 10 then true  else false
                        else
                                @SupportMessage = 'browser_unsupported'
                                return false
                        if !uptodate 
                                @SupportMessage = 'browser_outdated'
                        return uptodate

        browserIsFirefox: ()=>
                userAgent = @$window.navigator.userAgent
                isFirefox = new RegExp(/firefox/i)
                return isFirefox.test(userAgent)

        setLanguage: (lang)=>
                @mapIsLoading = true
                @$rootScope.chosen_language = lang
                # Load map once the page has loaded
                arte_api = angular.element("#arte-header")
                arte_api.data("plugin-arte-header").destroy()
                arte_api.arteHeader({'lang': lang});
                console.log("loading map...")
                @$timeout(()=>
                        this.load()
                ,50)
                lang_code = switch
                    when lang == 'fr' then 1
                    when lang == 'de' then 2
                    when lang == 'en' then 3
                    else 1
                return xt_click(this,'C',lang_code, 'world_brain::home','N')

        addCluster: (id, aCluster)=>
                """
                add a cluster to the list of clusters
                """
                @clusters[id] = aCluster
                return aCluster

        fireLoadedEvent: ()=>
                """
                When all clusters have loaded
                """
                @dataLoaded = true
                @$rootScope.$broadcast('dataLoaded')
                console.log('data loaded')

        load: ()=>
                @Restangular.one(@$rootScope.chosen_language).one('json/themes').get({full:true, files_folder:'files_low'}).then((data)=>
                        console.log( " === Loading data from worldbrain service === "   )
                        try
                            # ...
                            @pages = data.page
                            console.log(' Page data = ', @pages)
                        catch e
                            # ...
                            console.log(" error getting page data")
                        for cluster in data.clusters_list
                                this.addCluster(cluster.id, cluster)
                        # Build timeline list
                        total_duration = 0
                        $.each(config.durations, ()->
                            total_duration += this
                        )
                        for cluster_id, i in config.playlist_cluster_order
                            @$rootScope.timeline[i] = {
                                cluster_id : cluster_id
                                name : @clusters[cluster_id].data.name
                                length : (100*config.durations[i]/total_duration)-0.3
                                played : false
                            }
                        this.fireLoadedEvent()
                )
                #Offline loading
                # clusters_list = window.clusters_list
                # @pages = window.page
                # console.log( " === Loading data  === ", clusters_list   )
                # for cluster in clusters_list
                #        this.addCluster(cluster.id, cluster)
                # this.fireLoadedEvent()
                
        exitIntro: ()=>
                console.log("[Map Service] Exit intro !")
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
                                    # remove ng-cloak css rules
                                    #angular.element('style:contains("ng-cloak")').remove()    
                        }
                )
                return true

        showAboutPage:(sectionToShow)=>
                """
                Show CRedit or info pages 
                """
                switch sectionToShow
                    when "info" then @showInfo = true
                    when "credits" then @showCredits = true
                # Pause playing video ? with broadcast signal if needed

        closeAboutPage:(sectionToShow)=>
                """
                Close CRedit or info pages 
                """
                switch sectionToShow
                    when "info" then @showInfo = false
                    when "credits" then @showCredits = false


class overlayPlayerService
        constructor:(@$compile, @$rootScope)->
                #@$rootScope.original_sequence_container = {}
                #@$rootScope.overlaid_player = {}
                @$rootScope.playlistIndex = -1
                @clusterOverlaidId = 0
                @overlayPlayerOn = false
                # Set focus zoom level
                this.setFocusZoomLevel()
                $(window).on("resize.doResize", ()=>
                    console.log(" -- Window resized --",window.innerWidth)
                    @$rootScope.$apply(()=>
                        this.setFocusZoomLevel()
                    )
                )


        setIndexManually:(cluster_id)=>
                """
                When a sequence is playing, forces index on playlist to match played sequence
                and reflect this on timeline
                """
                @$rootScope.playlistIndex = config.playlist_cluster_order.indexOf(cluster_id)
                @$rootScope.timeline[@$rootScope.playlistIndex].played = true
                console.log("[setIndexManually] Set playlist index to  ",  @$rootScope.playlistIndex )

        close:()=>
                """
                Send close overlay signal with currently overlaid cluster as param 
                (this param is set within cluster controller)
                """
                @$rootScope.$broadcast("close_overlay", @clusterOverlaidId)
                @clusterOverlaidId = 0

        playSequence:(seq_id)=>
                """
                Send signals to launch play of one sequence 
                """
                @$rootScope.$broadcast("focus_on_sequence", seq_id)
                @$rootScope.$broadcast("move_and_play", seq_id)

        playCurrentSequence:()=>
                seq_id = config.playlist_cluster_order[@$rootScope.playlistIndex]
                this.playSequence(seq_id)

        setClusterOverlaidId:(id)=>
                @clusterOverlaidId = id

        setFocusZoomLevel:()=>
                """
                Set zoom level and overlay player size when playing sequences according to screen resolution
                """
                #console.log(" ++ screen res ", screen.availWidth)
                try
                        @$rootScope.focusZoomLevel = switch
                                when ( window.innerWidth > 1420 && window.innerWidth < 2820 ) then 5
                                when ( window.innerWidth > 2820 ) then 6
                                else 4
                        # if window ratio is more rectangular than video:
                        if ((window.innerHeight-60)/(window.innerWidth-100)) < ((config.videoStandardHeight/config.videoStandardWidth))
                                @$rootScope.playerHeight = window.innerHeight - 60
                                @$rootScope.playerWidth = parseInt((config.videoStandardWidth * @$rootScope.playerHeight) / config.videoStandardHeight)
                        else
                                @$rootScope.playerWidth = window.innerWidth - 150
                                @$rootScope.playerHeight = parseInt((config.videoStandardHeight * @$rootScope.playerWidth) / config.videoStandardWidth)
                catch e
                        # Default value if something goes wrong
                        @$rootScope.focusZoomLevel = 5
                        @$rootScope.playerWidth = 1200
                        @$rootScope.playerHeight = 662
                @$rootScope.playerMarginLeft = -parseInt(@$rootScope.playerWidth / 2)
                @$rootScope.playerMarginTop = -parseInt(@$rootScope.playerHeight / 2)
                console.log(" playerWidth= "+@$rootScope.playerWidth+" playerHeight= "+@$rootScope.playerHeight)


# Services
services.factory('MapService', ['$compile', 'Restangular', '$http', '$rootScope', '$timeout', '$window', ($compile, Restangular, $http, $rootScope, $timeout, $window) ->
        return new MapService($compile, Restangular, $http, $rootScope, $timeout, $window)
])
services.factory('overlayPlayerService', ['$compile', '$rootScope', ($compile, $rootScope) ->
        return new overlayPlayerService($compile, $rootScope)
])