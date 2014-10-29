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
                        # TODO : set language selector here
                        @Restangular.one('theme', cluster.id).get().then((cluster_data)=>
                            console.log( " === cluster  ", cluster_data.cluster[0])
                            cluster = cluster_data.cluster[0]
                            this.addCluster(cluster.id, cluster)
                            # Once last is loaded, set mapLoaded
                            i++
                            if i >= data.clusters_list.length-1
                                @mapLoaded = true
                                @mapIsLoading = false
                            )
                    )

# Services
services.factory('MapService', ['$compile', 'Restangular', '$http', '$rootScope', ($compile, Restangular, $http, $rootScope) ->
        return new MapService($compile, Restangular, $http, $rootScope)
])
