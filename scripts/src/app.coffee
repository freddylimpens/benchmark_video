angular.element(document).on('ready page:load', ->

        angular.module('wb_modules', ['wb.controllers', 'wb.services', 'leaflet-directive'])

        angular.module('world_brain', ['wb_modules', 'ui.router', 'ngAnimate', 'restangular'])

        # CORS
        .config(['$httpProvider', ($httpProvider) ->
                $httpProvider.defaults.useXDomain = true
                delete $httpProvider.defaults.headers.common['X-Requested-With']
        ])

        # Tastypie
        .config((RestangularProvider) ->
                RestangularProvider.setBaseUrl(config.rest_uri)
                # RestangularProvider.setDefaultHeaders({"Authorization": "ApiKey pipo:46fbf0f29a849563ebd36176e1352169fd486787"});
                # Tastypie patch
                RestangularProvider.setResponseExtractor((response, operation, what, url) ->
                        newResponse = null;

                        if operation is "getList"
                                newResponse = response.objects
                                newResponse.metadata = response.meta
                        else
                                newResponse = response

                        return newResponse
                )
        )


        # URI config
        .config(['$locationProvider', '$stateProvider', '$urlRouterProvider', ($locationProvider, $stateProvider, $urlRouterProvider) ->
                $locationProvider.html5Mode(config.useHtml5Mode)
                $urlRouterProvider.otherwise("/")

                $stateProvider.state('map',
                        url: '/',
                        templateUrl: "views/map.html",
                        controller: 'MapCtrl'
                )
        ])

        .run(['$rootScope', '$state', '$stateParams', 'MapService', ($rootScope, $state, $stateParams, MapService) ->
                $rootScope.homeStateName = 'apps' # Should be moved to loginServiceProvider
                $rootScope.config = config
                $rootScope.$state = $state
                $rootScope.$stateParams = $stateParams
                $rootScope.MapService = MapService
        ])

        console.debug("running angular app...")
        angular.bootstrap(document, ['world_brain'])


)