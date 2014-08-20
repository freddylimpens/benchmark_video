# -*- tab-width: 4 -*-
module = angular.module("leaflet-directive", [])

class LeafletController
    constructor: (@$scope) ->
        @$scope.marker_instances = []

    # addMarker: (lat, lng, options) =>
    #     marker = new L.marker([lat, lng], options).addTo(@$scope.map)

    #     return marker

    # removeMarker: (aMarker) =>
    #     @$scope.map.removeLayer(aMarker)


module.controller("LeafletController", ['$scope', LeafletController])

module.directive("leaflet", ["$http", "$log", "$location", ($http, $log, $location) ->
    return {
        restrict: "E"
        replace: true
        transclude: true
        scope:
            center: "=center"
            tilelayer: "=tilelayer"
            path: "=path"
            maxZoom: "@maxzoom"

        template: '<div class="angular-leaflet-map"><div ng-transclude></div></div>'

        controller: 'LeafletController'

        link: ($scope, element, attrs, ctrl) ->
            console.debug("attrs object = ", attrs)
            $el = element[0]

            $scope.map = new L.Map($el,
                zoomControl: true
                zoomAnimation: true
                # crs: L.CRS.EPSG4326
            )
            # Center
            # Change callback
            $scope.$watch("center", ((center, oldValue) ->
                    console.debug("map center changed")
                    $scope.map.setView([center.lat, center.lng], center.zoom)
                ), true
            )

            maxZoom = $scope.maxZoom or 12

            # video / canvas layer
            VideoTestLayer = L.CanvasLayer.extend({
                renderCircle: (ctx, point, radius)->
                    ctx.fillStyle = 'rgba(255, 60, 60, 0.2)'
                    ctx.strokeStyle = 'rgba(255, 60, 60, 0.9)'
                    ctx.beginPath()
                    ctx.arc(point.x, point.y, radius, 0, Math.PI * 2.0, true, true)
                    ctx.closePath()
                    ctx.fill()
                    ctx.stroke()

                render: (currentZoom) ->
                    currentZoom = $scope.map.getZoom() || 1
                    console.debug("current zoom  = ", currentZoom)
                    canvas = this.getCanvas()
                    ctx = canvas.getContext('2d')

                    #clear canvas
                    ctx.clearRect(0, 0, canvas.width, canvas.height)

                    #get center from the map (projected)
                    point = this._map.latLngToContainerPoint(new L.LatLng(0, 0))
                    scale = L.CRS.EPSG3857.scale(currentZoom)
                    #console.debug("scale = ",scale)
                    #render
                    #this.renderCircle(ctx, point, (1.0 + Math.sin(Date.now()*0.001))*30*currentZoom)
                    this.renderCircle(ctx, point, 10*scale/1000)
                    this.redraw()
                
            })
            
            # HTML Layer
            MyCustomLayer = L.Class.extend({
                initialize: (latlng) ->
                    #save position of the layer or any options from the constructor
                    this._latlng = latlng

                onAdd: (map) ->
                    this._map = map;

                    #create a DOM element and put it into one of the map panes
                    #this._el = L.DomUtil.create('div', 'my-custom-layer leaflet-zoom-hide')
                    this._el = L.DomUtil.get('article_content')
                    console.log(' ## article element = ', this._el)
                    map.getPanes().overlayPane.appendChild(this._el)

                    #add a viewreset event listener for updating layer's position, do the latter
                    map.on('viewreset', this._reset, this)
                    this._reset()

                onRemove: (map) ->
                    #remove layer's DOM elements and listeners
                    map.getPanes().overlayPane.removeChild(this._el)
                    map.off('viewreset', this._reset, this)

                _reset: () ->
                    #update layer's position
                    pos = this._map.latLngToLayerPoint(this._latlng)
                    L.DomUtil.setPosition(this._el, pos)
            
            })

            # Tile layers. XXX Should be a sub directive?
            $scope.$watch("tilelayer", (layer, oldLayer) =>
                # Remove current layers
                $scope.map.eachLayer((layer) =>
                    console.debug("removed layer #{layer._url}")
                    $scope.map.removeLayer(layer)
                )

                # Add new ones
                if layer
                    console.debug("installing new layer #{layer.url_template}")
                    L.tileLayer(layer.url_template, layer.attribution).addTo($scope.map)
                # add circle layer
                console.debug(" adding circle layer")
                $scope.video_layer = new VideoTestLayer()
                $scope.video_layer.addTo($scope.map)
                # add html layer
                center = new L.LatLng(0, 0)
                $scope.map.addLayer(new MyCustomLayer(center));
            , true
            )
            $scope.map.on('zoomend', (e)->
                zoom = $scope.map.getZoom()
                console.debug(" zoom level changed = ", zoom)

                )


    }
])
