angular.element(document).on('ready page:load', ->

        angular.module('wb_modules', ['wb.controllers', 'wb.services','wb_filters', 'leaflet-directive'])

        angular.module('world_brain', ['wb_modules', 'ui.router', 'restangular', 'ngSanitize', 'pasvaz.bindonce'])

        # CORS
        .config(['$httpProvider', ($httpProvider) ->
                $httpProvider.defaults.useXDomain = true
                delete $httpProvider.defaults.headers.common['X-Requested-With']
                #$httpProvider.defaults.headers.common.Authorization = "Basic ZHc6ZHVub2lz"
                return true
        ])

        # Allow iframe loading from Arte
        .config(($sceDelegateProvider) -> 
                $sceDelegateProvider.resourceUrlWhitelist([
                    # Allow same origin resource loads
                    'self',
                    # Allow loading from Arte
                    'http://www.arte.tv/**',
                    # data from WOrldbrain API
                    'http://worldbrain.fr/**',
                    'http://backend.arte.tv',
                    'http://worldbrain.arte.tv'
                ])
        )

        # Tastypie
        .config((RestangularProvider) ->
                RestangularProvider.setBaseUrl(config.rest_uri)
                #RestangularProvider.setDefaultHeaders({"Authorization" : "Basic ZHc6ZHVub2lz"})
        )

        # URI config
        .config(['$locationProvider', '$stateProvider', '$urlRouterProvider', ($locationProvider, $stateProvider, $urlRouterProvider) ->
                $locationProvider.html5Mode(config.useHtml5Mode)
                $urlRouterProvider.otherwise("/")

                # $stateProvider.state('home',
                #         url: '/',
                #         templateUrl: "views/home.html",
                #         #controller: 'MapCtrl'
                # )

                $stateProvider.state('map',
                        url: '/',
                        templateUrl: "views/map.html",
                        controller: 'MapCtrl'
                )
        ])

        .run(['$rootScope', '$state', '$stateParams', 'MapService', 'overlayPlayerService', ($rootScope, $state, $stateParams, MapService, overlayPlayerService) ->
                $rootScope.homeStateName = 'apps' # Should be moved to loginServiceProvider
                $rootScope.config = config
                $rootScope.$state = $state
                $rootScope.$stateParams = $stateParams
                $rootScope.MapService = MapService
                $rootScope.overlayPlayerService = overlayPlayerService
        ])

        console.log("running angular app...")
        angular.bootstrap(document, ['world_brain'])
        

)
