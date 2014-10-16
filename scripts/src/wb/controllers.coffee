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

# Controller declarations
module.controller("MapCtrl", ['$scope', '$rootScope', '$stateParams', 'MapService', MapCtrl])
