services = angular.module('wb.services', ['restangular'])

class MapService
        constructor: (@$compile, @Restangular, @$http, @$rootScope) ->
                # Center given in pixel coordinates
                @center =
                        top: 6466
                        left: 11314
                        zoom: 1

                @clusters = {}
                @mapLoaded = false
                @mapIsLoading = false

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

        load: ()=>
                # get clusters data from Wweb service or Json file
                #clusters_list = window.clusters_list
                @Restangular.one('themes').get().then((data)=>
                    console.log( " === Loading data from worldbrain service === ", data.clusters_list)
                    #clusters_list = data.clusters_list
                    i = 0
                    for cluster in data.clusters_list
                        
                        console.log(" === BEFORE for loop index = "+i+" list length = "+data.clusters_list.length+" cluster id =", cluster.id)
                        # TODO : set language selector here
                        @Restangular.one('theme', cluster.id).get().then((cluster_data)=>
                            i++
                            console.log(" === for loop index = "+i+" list length = "+data.clusters_list.length)
                            console.log( " === loading cluster  ", cluster_data.cluster[0].id)
                            console.log( " === cluster data = ", cluster_data.cluster[0])
                            # Once last is loaded, set mapLoaded
                            if i >= data.clusters_list.length
                                @mapLoaded = true
                                @mapIsLoading = false
                            console.log(" Before adding cluster to clusters list")
                            cluster = cluster_data.cluster[0]
                            this.addCluster(cluster.id, cluster)
                            console.log(" After adding cluster to clusters list = ", @clusters)
                        , (error_message)=>
                            console.log(" === Error loading cluster "+cluster.id+" message = ", error_message)
                            i++
                            # Once last is loaded, set mapLoaded
                            if i >= data.clusters_list.length
                                @mapLoaded = true
                                @mapIsLoading = false
                            )
                )

# Services
services.factory('MapService', ['$compile', 'Restangular', '$http', '$rootScope', ($compile, Restangular, $http, $rootScope) ->
        return new MapService($compile, Restangular, $http, $rootScope)
])
