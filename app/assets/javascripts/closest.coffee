$(->
  L.mapbox.accessToken = 'pk.eyJ1IjoidmJoamNrZmQiLCJhIjoiY2ltMjNidDRvMDBudnVvbTQ4aGQ2bTFzNiJ9.I5ym_chknrWXKf5hXD6anA';

  map = L.map('map', {
    center: [0, 0]
  })
  L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png').addTo(map);

  stop_markers = {}

  map.on 'moveend', (e)->
    if e.target.getZoom() < 16
      for code, marker of stop_markers
        e.target.removeLayer(marker)
      stop_markers = {}
      return

    center = e.target.getCenter()

    $.ajax(
      url: 'api/closest'
      data:
        longitude: center.lng
        latitude: center.lat
        accuracy: 200
    ).done (data) ->
      showMap null, data

  showClosestStops = (position) ->
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

    if me
      map.setZoom(17).panTo(me)
      L.marker(me).addTo(map)

    if stops
      jQuery.each stops, (index, value)-> 
        if value.code of stop_markers
          return

        stop_markers[value.code] = L.marker([value.latitude, value.longitude], {
          icon: L.icon({
            iconUrl: 'https://api.mapbox.com/v4/marker/pin-l-bus+fa0.png?access_token=' + L.mapbox.accessToken,
            iconAnchor: [20, 50],
          })
          title: value.code,
          url: 'stops/' + value.code
        }).addTo(map)

        stop_markers[value.code].on 'click', (e) ->
          window.location.pathname = e.target.options.url

  if navigator.geolocation
    $('div#geo-available').show()

  $('a#geo-lnk').click ->
    $('img#spinner').show()
    options = 
      enableHighAccuracy: true
      timeout: 6000
      maximumAge: 10000
    navigator.geolocation.getCurrentPosition showClosestStops, ((error) ->
      alert(String(error))
    ), options
    return false

  $('form#stop-code-form').submit ->
    code = $('input#stop-code').val()
    if code
      window.location.pathname = 'stops/' + code
    return false
)
