"use strict"

var initMap = function() {
  var stop_markers = {};
  var map;

  var createMap = function() {
    if ('undefined' !== typeof map) {
      return;
    }

    $('div#map').show();

    map = new google.maps.Map(document.getElementById('map'), {
      center: {lat: 49.840733, lng: 24.028164},
      zoom: 18,
      streetViewControl: false,
      fullscreenControl: false,
      mapTypeControl: false,
      zoomControlOptions: {
          position: google.maps.ControlPosition.TOP_LEFT
      },
    });

    var refreshStops = function() {
        var center, code, marker;

        if (map.getZoom() < 17) {
          for (code in stop_markers) {
            marker = stop_markers[code];
            marker.setMap(null);
          }
          stop_markers = {};
          return;
        }

        center = map.getCenter();
        $.ajax({
          url: 'api/closest',
          data: {
            longitude: center.lng(),
            latitude: center.lat()
          }
        }).done(function(data) {
          return showMap(null, data);
        });

        var state = {
          lng: center.lng(),
          lat: center.lat(),
          z: map.getZoom()
        };

        history.pushState(state, null, '?' + jQuery.param(state));
    };

    map.addListener('dragend', refreshStops);
    map.addListener('zoom_changed', refreshStops);
  }

  var showCityCenter = function() {
    showClosestStops({
      coords: {latitude: 49.840733, longitude: 24.028164}
    });
  }

  var showClosestStops = function(position) {
    showMap({lat: position.coords.latitude, lng: position.coords.longitude});
    $('img#spinner').hide();
  };

  var showMap = function(me, stops) {
    createMap();

    if (me) {
      map.panTo(me);

      var meMarker = new google.maps.Marker({
        position: me,
        map: map,
        icon: {
          url: 'http://i.imgur.com/fyrG0CJ.png',
          anchor: new google.maps.Point(20, 50)
        }
      });
    }

    if (stops) {
      return $.each(stops, function(index, value) {
        if (value.code in stop_markers) {
          return;
        }

        var marker = new google.maps.Marker({
          position: {lat: value.latitude, lng: value.longitude},
          title: value.code.toString(),
          label: value.code.toString()
        })

        marker.addListener('click', function(e) {
          return window.location.assign('/stops/' + this.title);
        });
        marker.setMap(map);

        stop_markers[value.code] = marker;
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


}
