$(->
  L.mapbox.accessToken = 'pk.eyJ1IjoidmJoamNrZmQiLCJhIjoiY2ltMjNidDRvMDBudnVvbTQ4aGQ2bTFzNiJ9.I5ym_chknrWXKf5hXD6anA';

  redirectToClosestStop = (position) ->
    $.ajax(
      url: 'api/closest'
      data:
        longitude: position.coords.longitude
        latitude: position.coords.latitude
        accuracy: 100
    ).done((data) ->
      $('a#geo-lnk').hide()
      showMap [position.coords.latitude, position.coords.longitude], data

    ).fail((data) ->
      message = 'Some temporary problems...'
      if 404 == data.status
        message = 'Поруч не знайдено зупинок, вибачте :('
      alert message
      showMap [position.coords.latitude, position.coords.longitude]
    ).always (data) ->
      $('img#spinner').hide()

  showMap = (me, stops) ->
    $('div#map').show()
    map = L.mapbox.map('map', 'mapbox.streets').setView(me, 17);

    geojson = {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          properties: {
              title: 'Ви',
              'marker-color': '#7ec9b1',
              'marker-size': 'large',
              'marker-symbol': 'pitch',
          },
          geometry: {
              type: 'Point',
              coordinates: me.reverse()
          }
        },
      ]
    };

    if stops
      jQuery.each stops, (index, value)-> 
        geojson.features.push {
            type: 'Feature',
            properties: {
                title: value.code,
                'marker-color': '#7ec9b1',
                'marker-size': 'large',
                'marker-symbol': 'bus',
                url: 'stops/' + value.code
            },
            geometry: {
                type: 'Point',
                coordinates: [value.longitude, value.latitude]
            }
          }

    markerLayer = L.mapbox.featureLayer().addTo(map);
    markerLayer.setGeoJSON geojson
    markerLayer.on 'click', (e) ->
      if e.layer.feature.properties.url
        window.location.pathname = e.layer.feature.properties.url

  if navigator.geolocation
    $('div#geo-available').show()

  $('a#geo-lnk').click ->
    $('img#spinner').show()
    options = 
      enableHighAccuracy: false
      timeout: 5000
      maximumAge: 10000
    navigator.geolocation.getCurrentPosition redirectToClosestStop, ((error) ->
      alert(String(error))
    ), options
    return false

  $('form#stop-code-form').submit ->
    code = $('input#stop-code').val()
    if code
      window.location.pathname = 'stops/' + code
    return false
)
