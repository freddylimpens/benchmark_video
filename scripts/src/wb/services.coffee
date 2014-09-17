services = angular.module('wb.services', ['restangular'])

class MapService
        constructor: (@$compile, @Restangular) ->
                @center =
                        lat: 0.0
                        lng: 0.0
                        zoom: 1

                @tilelayer = 
                        url_template: 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
                        attribution: 'Map data © OpenStreetMap contributors'

                @map = null

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
                # clusters_list = [
                #     {
                #         id : 1
                #         column: 0
                #         order_in_column: 0
                #         data: "cluster 1 data"
                #     },
                #     {
                #         id:2
                #         column: 1
                #         order_in_column: 1
                #         data: "cluster 2 data"
                #     }
                #     {
                #         id : 3
                #         column: 0
                #         order_in_column: 1
                #         data: "cluster 1 data"
                #     },
                #     {
                #         id:4
                #         column: 1
                #         order_in_column: 0
                #         data: "cluster 2 data"
                #     }

                # ]
                
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
                            

class ClusterService
        constructor: (@$compile, @Restangular) ->



# Services
services.factory('MapService', ['$compile', 'Restangular', ($compile, Restangular) ->
        return new MapService($compile, Restangular)
])

services.factory('ClusterService', ['$compile', 'Restangular', ($compile, Restangular) ->
        return new MapService($compile, Restangular)
])