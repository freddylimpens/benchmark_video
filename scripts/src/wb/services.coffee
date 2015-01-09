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
                # Map loading vars
                @mapIsLoading = false
                @dataLoaded = false
                @BrowserSupported = this.checkBrowserSupported()
                # get Browser
                @$rootScope.onFirefox = this.browserIsFirefox()
                console.log(" firefox ?? ", @$rootScope.onFirefox)
                @showCredits = false
                @showInfo = false
        
        checkBrowserSupported:()=>
                return true

        browserIsFirefox: ()=>
                userAgent = @$window.navigator.userAgent
                isFirefox = new RegExp(/firefox/i)
                return isFirefox.test(userAgent)

        setLanguage: (lang)=>
                @$rootScope.chosen_language = lang
                @mapIsLoading = true
                # Load map once the page has loaded
                console.debug("loading map...")
                this.load()

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
                #clusters_list = window.clusters_list
                #@Restangular.one('themes').get({full:true, files_folder:'files_low'}).then((data)=>
                @Restangular.one('code64.json').get().then((data)=>
                        console.log( " === Loading data from worldbrain service === "   )
                        #clusters_list = data.clusters_list
                        for cluster in data.clusters_list
                                this.addCluster(cluster.id, cluster)
                        this.fireLoadedEvent()
                )

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