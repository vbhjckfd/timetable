"use strict"

$(function() {
  var stop_markers = {};
  var map;

  var initMap = function() {
    if ('undefined' !== typeof map) {
      return;
    }

    $('div#map').show();

    map = L.map('map', {
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
          latitude: center.lat
        }
      }).done(function(data) {
        return showMap(null, data);
      });
    });
  }

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
    initMap();

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
            iconUrl: 'http://i.imgur.com/fyrG0CJ.png',
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

  $('form#stop-search').submit(function() {
    var stop_code = $(this).find('#stop-code').val();
    if (!stop_code) {
      return false;
    }
    window.location.assign('/stops/' + stop_code);
    return false;
  });

  if (navigator.geolocation) {
    // Try to use GPS
    navigator.geolocation.getCurrentPosition(showClosestStops, function(error) {
      switch(error.code) {
        case error.TIMEOUT:
          // Use LBS or whatever google services have
          navigator.geolocation.getCurrentPosition(showClosestStops, function(error) {
            showCityCenter();
          }, {timeout: 1000, maximumAge: Infinity});
          break;
        default:
          showCityCenter();
      }
    }, {enableHighAccuracy: true, timeout: 3000, maximumAge: 10000});
  } else {
    showCityCenter();
  }


});
