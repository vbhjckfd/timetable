require 'json'

class Api::StopController < ApplicationController

  def show
    stop_id = params[:id]
    stop = Stop.where(code: stop_id).first

    return render(status: :bad_request, text: "No stop with code #{stop_id}") unless stop

    timetable = Rails.cache.fetch("stop_timetable/#{stop_id}", expires_in: 15.seconds) do
      stop.get_timetable
    end
    response = stop.as_json.symbolize_keys.slice(:name, :longitude, :latitude, :code).merge timetable: timetable || []

    response[:routes] = Route.through(stop).map{|r| r.name }

    render json: response
  end

  def closest
    coords = params.slice(:longitude, :latitude)
    accuracy = params[:accuracy] || 10
    render(status: :bad_request, text: "No coordinates provided (longitude, latitude)") if coords.count != 2

    point = Geokit::LatLng.new(params[:latitude], params[:longitude])
    stops = Stop.in_lviv.within(accuracy.to_f / 1000 * 2, origin: point).by_distance(origin: point).slice(0, 10).map{|stop| {code: stop.code, name: stop.name, longitude: stop.longitude, latitude: stop.latitude} }

    render json: stops
  end

end
