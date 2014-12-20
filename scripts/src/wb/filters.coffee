wb_filters = angular.module('wb_filters', [])

wb_filters.filter('escape', () ->
    return window.encodeURIComponent
)
