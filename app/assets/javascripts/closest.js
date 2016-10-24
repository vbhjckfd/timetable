"use strict"

$(function() {
  L.mapbox.accessToken = 'pk.eyJ1IjoidmJoamNrZmQiLCJhIjoiY2ltMjNidDRvMDBudnVvbTQ4aGQ2bTFzNiJ9.I5ym_chknrWXKf5hXD6anA';

  var stop_markers = {};

  var map = L.map('map', {
    center: [0, 0]
  });
  L.tileLayer('//{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

  map.on('moveend', function(e) {
    var center, code, marker;

    if (e.target.getZoom() < 16) {
      for (code in stop_markers) {
        marker = stop_markers[code];
        e.target.removeLayer(marker);
      }
      stop_markers = {};
      return;
    }

    center = e.target.getCenter();
    return $.ajax({
      url: 'api/closest',
      data: {
        longitude: center.lng,
        latitude: center.lat,
        accuracy: 200
      }
    }).done(function(data) {
      return showMap(center, data);
    });
  });

  var showCityCenter = function() {
    showClosestStops({
      coords: {latitude: 49.840733, longitude: 24.028164}
    });
  }

  var showClosestStops = function(position) {
    showMap([position.coords.latitude, position.coords.longitude]);
    $('img#spinner').hide();
  };

  var showMap = function(me, stops) {
    $('div#map').show();

    if (me) {
      map.setZoom(17).panTo(me);
      L.marker(me).addTo(map);
    }

    if (stops) {
      return $.each(stops, function(index, value) {
        if (value.code in stop_markers) {
          return;
        }
        stop_markers[value.code] = L.marker([value.latitude, value.longitude], {
          icon: L.icon({
            iconUrl: 'https://api.mapbox.com/v4/marker/pin-l-bus+fa0.png?access_token=' + L.mapbox.accessToken,
            iconAnchor: [20, 50]
          }),
          title: value.code,
          url: 'stops/' + value.code
        }).addTo(map);
        return stop_markers[value.code].on('click', function(e) {
          return window.location.pathname = e.target.options.url;
        });
      });
    }
  };

  if (navigator.geolocation) {
    var options = {
      enableHighAccuracy: true,
      timeout: 6000,
      maximumAge: 10000
    };
    navigator.geolocation.getCurrentPosition(showClosestStops, function(error) {
      showCityCenter();
    }, options);
  } else {
    showCityCenter();
  }

  return $('form#stop-code-form').submit(function() {
    var code = $('input#stop-code').val();
    if (code) {
      window.location.pathname = 'stops/' + code;
    }
    return false;
  });
});
