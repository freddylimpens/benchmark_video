services = angular.module('wb.services', ['restangular'])

class MapService
        constructor: (@$compile, @Restangular) ->
                @center =
                        lat: -72.0
                        lng: 93.0
                        zoom: 2

                @clusters = {}

        addCluster: (id, aCluster)=>
                """
                add a cluster to the list of clusters
                """
                @clusters[id] = aCluster
                return aCluster

        load: ()=>
                # get clusters data from Wweb service or Json file
                clusters_list = window.clusters_list
                console.log(" ===  DATA LOADED ==== ", clusters_list)
                # Sort clusters_list to be sure to take clusters in the same order each time 
                # (the id is not used here)
                clusters_list = _(clusters_list).sortBy((cluster)->
                    return cluster.order_in_column
                    )
                clusters_list = _(clusters_list).sortBy((cluster)->
                    return cluster.column
                    )
                i = 0
                for cluster in clusters_list
                        this.addCluster(i, cluster)
                        i++

# Services
services.factory('MapService', ['$compile', 'Restangular', ($compile, Restangular) ->
        return new MapService($compile, Restangular)
])
