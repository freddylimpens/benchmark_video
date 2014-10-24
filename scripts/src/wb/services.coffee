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
                # @$rootScope.$watch('clusters',(newVal, oldVal)=>
                #     console.log(" [wtach] clusters updated", @clusters)
                #     )

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
                    for cluster in data.clusters_list
                        # TODO : set language selector here
                        @Restangular.one('theme', cluster.id).get().then((data)=>
                            console.log( " === cluster  ", data.cluster[0])
                            cluster = data.cluster[0]
                            this.addCluster(cluster.id, cluster)
                            # FIXME : do this only on last cluster loaded
                            @mapLoaded = true
                            @mapIsLoading = false
                            )
                    )

                # console.log(" ===  DATA LOADED ==== ", clusters_list)
                # # Sort clusters_list to be sure to take clusters in the same order each time 
                # # (the id is not used here)
                # clusters_list = _(clusters_list).sortBy((cluster)->
                #     return cluster.order_in_column
                #     )
                # clusters_list = _(clusters_list).sortBy((cluster)->
                #     return cluster.column
                #     )
                # i = 0
                # for cluster in clusters_list
                #         this.addCluster(i, cluster)
                #         i++

# Services
services.factory('MapService', ['$compile', 'Restangular', '$http', '$rootScope', ($compile, Restangular, $http, $rootScope) ->
        return new MapService($compile, Restangular, $http, $rootScope)
])
