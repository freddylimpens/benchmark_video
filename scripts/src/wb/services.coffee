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

class ClusterService
        constructor: (@$compile, @Restangular) ->



# Services
services.factory('MapService', ['$compile', 'Restangular', ($compile, Restangular) ->
        return new MapService($compile, Restangular)
])

services.factory('ClusterService', ['$compile', 'Restangular', ($compile, Restangular) ->
        return new MapService($compile, Restangular)
])