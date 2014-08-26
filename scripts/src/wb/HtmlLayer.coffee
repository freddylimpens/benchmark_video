# HTML Layer
HtmlLayer = L.Class.extend({

options:
    opacity: 1
    alt: ''
    zoomAnimation: true

initialize: (bounds, html_content, options) ->
    #save position of the layer or any options from the constructor
    console.log("INIT : setting bounds")
    this._bounds = L.latLngBounds(bounds)
    this._el = html_content
    #L.setOptions(this, options);

onAdd: (map) ->
    this._map = map;
    #create a DOM element and put it into one of the map panes
    #L.DomUtil.addClass(this._el, 'leaflet-zoom-animated')
    console.log(' ## article element = ', this._el)
    map.getPanes().overlayPane.appendChild(this._el)
    console.log("layer added")
    
    #add a viewreset event listener for updating layer's position, do the latter
    map.on('viewreset', this._reset, this)
    map.on('zoomstart', this._getOldSize, this)
    map.on('zoomanim', this._animateZoom, this)
    this._reset()

getEvents: ()->
    events = 
        viewreset: this._reset
        zoomanim: this._animateZoom
    
    if (this._zoomAnimated)
        events.zoomanim = this._animateZoom
    
    return events

getBounds: ()->
    return this._bounds

onRemove: (map) ->
    #remove layer's DOM elements and listeners
    map.getPanes().overlayPane.removeChild(this._el)
    map.off('viewreset', this._reset, this)

_animateZoom: (e)->
    # built in animation mechanism depends on projected size (geo > screen space); 
    # hence, the following does not play well with zoom-only variation of size (see _reset)   
    console.log(" animating zoom...") 
    topLeft = this._map._latLngToNewLayerPoint(this._bounds.getNorthWest(), e.zoom, e.center)
    size = this._map._latLngToNewLayerPoint(this._bounds.getSouthEast(), e.zoom, e.center).subtract(topLeft)
    scale = this._map.getZoomScale(e.zoom)
    origin = topLeft._add(size._multiplyBy((1 - 1 / scale) / 2));
    this._el.childNodes[1].style[L.DomUtil.TRANSFORM] = L.DomUtil.getTranslateString(origin) + ' scale(' + scale + ') ';

_reset: () ->
    #update layer's position with bounds
    html_layer = this._el
    bounds = new L.Bounds(
        this._map.latLngToLayerPoint(this._bounds.getNorthWest()),
        this._map.latLngToLayerPoint(this._bounds.getSouthEast()))
    L.DomUtil.setPosition(html_layer, bounds.getCenter())
    # apply scale with current zoom
    c_z = this._map.getZoom()
    html_layer.childNodes[1].style =  'transform: scale('+ c_z*0.05+','+c_z*0.05+');'
    console.log("style changed ?", html_layer.childNodes[1].style)
})

L.htmlLayer = (bounds, html, options)->
    return new L.HtmlLayer(bounds, html, options);