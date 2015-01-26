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
                @clusterOverlaidId = 0
                @overlayPlayerOn = false

        close:()=>
                """
                Send close overlay signal with currently overlaid cluster as param 
                (this param is set within cluster controller)
                """
                @$rootScope.$broadcast("close_overlay", @clusterOverlaidId)
                @clusterOverlaidId = 0

        setClusterOverlaidId:(id)=>
                @clusterOverlaidId = id





# Services
services.factory('MapService', ['$compile', 'Restangular', '$http', '$rootScope', '$timeout', '$window', ($compile, Restangular, $http, $rootScope, $timeout, $window) ->
        return new MapService($compile, Restangular, $http, $rootScope, $timeout, $window)
])
services.factory('overlayPlayerService', ['$compile', '$rootScope', ($compile, $rootScope) ->
        return new overlayPlayerService($compile, $rootScope)
])
        # NOT USED SO FAR
        # overlayPlayer:(player_container)=>
        #         """
        #         Get player to overlay as param
        #         """
        #         if @$rootScope.onFirefox
        #                 console.log("playing overlay")
        #                 @$rootScope.overlayPlayerOn = true
        #                 cont = angular.element('#video-embed-container')
        #                 @$rootScope.original_sequence_container = player_container.parent()[0]
        #                 @$rootScope.overlaid_player = player_container
        #                 player_container.detach()
        #                 cont.append(@$rootScope.overlaid_player)


        # closeOverlayPlayer:()=>
        #         """
        #         Close overlay and restore player (player to restore to be in scope)
        #         """
        #         if @$rootScope.onFirefox
        #                 console.log("closing overlay player")
        #                 # reset which player ??
        #                 #this.resetArtePlayer()
        #                 @$rootScope.overlayPlayerOn = false
        #                 @$rootScope.overlaid_player.detach()
        #                 # reappend to original place
        #                 cont = $(@$rootScope.original_sequence_container)
        #                 cont.append(@$rootScope.overlaid_player)
        #                 @$rootScope.original_sequence_container = {}
        #                 @$rootScope.overlaid_player = {}
        #                 console.log("closed overlayPlayer")

# Below is the code to load data cluster by cluster
                    # i = 0
                    # for cluster in data.clusters_list
                    #     console.log(" === BEFORE for loop index = "+i+" list length = "+data.clusters_list.length+" cluster id =", cluster.id)
                    #     # TODO : set language selector here
                    #     @Restangular.one('theme', cluster.id).get().then((cluster_data)=>
                    #         i++
                    #         console.log(" === for loop index = "+i+" list length = "+data.clusters_list.length)
                    #         console.log( " === loading cluster  ", cluster_data.cluster[0].id)
                    #         console.log( " === cluster data = ", cluster_data.cluster[0])
                    #         console.log(" Before adding cluster to clusters list")
                    #         cluster = cluster_data.cluster[0]
                    #         this.addCluster(cluster.id, cluster)
                    #         console.log(" After adding cluster to clusters list = ", @clusters)
                    #         # Once last is loaded, set mapLoaded
                    #         if i >= data.clusters_list.length
                    #             this.fireLoadedEvent()
                    #     , (error_message)=>
                    #         console.log(" === Error loading cluster "+cluster.id+" message = ", error_message)
                    #         i++
                    #         # Once last is loaded, set mapLoaded
                    #         if i >= data.clusters_list.length
                    #             this.fireLoadedEvent()
                    #         )