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
                @MapService.load()


class ClusterCtrl
        """
        Controller dedicated to data interactions within a cluster
        """
        constructor:(@$scope, @ClusterService) ->
                @$scope.ClusterService = @ClusterService
                

        setIframeSrc:(iframeSrc) =>
                

# Controller declarations
module.controller("MapCtrl", ['$scope', '$rootScope', '$stateParams', 'MapService', MapCtrl])
module.controller("ClusterCtrl", ['$scope', 'ClusterService', ClusterCtrl])
