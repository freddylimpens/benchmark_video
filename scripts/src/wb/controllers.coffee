module = angular.module('wb.controllers', ['restangular', 'ui.router', 'wb.services'])

class HomeCtrl
        """
        Home controller
        """
        constructor: (@$scope, @$rootScope, @$state, @MapService, @overlayPlayerService) ->
                console.log("loading HOME controller..")
                @MapService.mapIsLoading = false
                @MapService.dataLoaded = false
                @$rootScope.mapLoaded = false
                # Reset overlay player toggles
                @overlayPlayerService.clusterOverlaidId = 0
                @overlayPlayerService.overlayPlayerOn = false
                @$scope.selectLanguage = this.selectLanguage

        selectLanguage:(lang)=>
                @$state.go('map', {chosenLang: lang})


# Controller declarations
module.controller("HomeCtrl", ['$scope', '$rootScope', '$state', 'MapService', 'overlayPlayerService', HomeCtrl])

class MapCtrl
        """
        Base controller that triggers data loading occuring in MapService
        """
        constructor: (@$scope, @$rootScope, @$stateParams, @MapService, @overlayPlayerService) ->
                console.log("loading map controller..")
                # Reset global variables
                @MapService.mapIsLoading = false
                @MapService.dataLoaded = false
                @$rootScope.mapLoaded = false
                @overlayPlayerService.clusterOverlaidId = 0
                @overlayPlayerService.overlayPlayerOn = false
                @MapService.clusters = {}
                @MapService.pages = {}
                # Set language from MapService
                @MapService.setLanguage(@$stateParams.chosenLang)

# Controller declarations
module.controller("MapCtrl", ['$scope', '$rootScope', '$stateParams', 'MapService', 'overlayPlayerService', MapCtrl])
