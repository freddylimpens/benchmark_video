services = angular.module('wb.services', ['restangular'])

class MapService
        constructor: (@$compile, @Restangular) ->
                
                @center =
                        lat: 1.0
                        lng: 1.0
                        zoom: 8

                @tilelayer = 
                        url_template: 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
                        attribution: 'Map data © OpenStreetMap contributors'

                @map = null

# Services
services.factory('MapService', ['$compile', 'Restangular', ($compile, Restangular) ->
        return new MapService($compile, Restangular)
])
