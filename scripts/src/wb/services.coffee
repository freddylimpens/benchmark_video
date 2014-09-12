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
                clusters_list = [
                    {
                        id : 1
                        pos_column: 1
                        pos_weight: 1
                        data: "cluster 1 data"
                    },
                    {
                        id:2
                        pos_column: 2
                        pos_weight: 1
                        data: "cluster 2 data"
                    }

                ]
                for cluster in clusters_list
                        this.addCluster(cluster.id, cluster)
                            

class ClusterService
        constructor: (@$compile, @Restangular) ->



# Services
services.factory('MapService', ['$compile', 'Restangular', ($compile, Restangular) ->
        return new MapService($compile, Restangular)
])

services.factory('ClusterService', ['$compile', 'Restangular', ($compile, Restangular) ->
        return new MapService($compile, Restangular)
])