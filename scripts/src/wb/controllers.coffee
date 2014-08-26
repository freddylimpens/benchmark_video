module = angular.module('wb.controllers', ['restangular', 'ui.router', 'wb.services'])

class MapCtrl
        """
        Base controller for interacting with the map
        """
        constructor: (@$scope, @$rootScope, @$stateParams, @MapService) ->
                @$scope.MapService = @MapService
                @$scope.$stateParams = @$stateParams

                # Load map once the page has loaded
                console.debug("loading map...")


class ClusterCtrl
        """
        Controller to fetch html clusters data 
        """
        constructor:(@$scope, @ClusterService) ->
                @$scope.ClusterService = @ClusterService

                @$scope.clusters = []
                @$scope.clusters[0] = {}
                @$scope.clusters[0].bounds = #L.latLngBounds(L.latLng(0,0), L.latLng(-40,40))
                        top_left_lat: 0.0
                        top_left_lng: 0.0
                        bot_right_lat: -40.0
                        bot_right_lng: 40.0


# Controller declarations
module.controller("MapCtrl", ['$scope', '$rootScope', '$stateParams', 'MapService', MapCtrl])
module.controller("ClusterCtrl", ['$scope', 'ClusterService', ClusterCtrl])
