require 'json'

class Api::StopController < ApplicationController

  def show
    stop_id = params[:id]
    stop = Stop.where(code: stop_id).first

    return render(status: :bad_request, text: "No stop with code #{stop_id}") unless stop

    #all_info = Rails.cache.fetch("stop_timetable/#{stop_id}", expires_in: 15.seconds) do
  #    stop.get_all_info
    #end

    timetable = stop.get_timetable
    response = stop.as_json.symbolize_keys.slice(:name, :longitude, :latitude, :code).merge timetable: timetable || []

    response[:routes] = Route.through(stop).map { |r|
      {
        name: r.name,
        type: r.vehicle_type,
      }
    }

    render json: response
  end

  def closest
    coords = params.slice(:longitude, :latitude)
    accuracy = 300
    render(status: :bad_request, text: "No coordinates provided (longitude, latitude)") if coords.count != 2

    point = Geokit::LatLng.new(params[:latitude].to_f.round(3), params[:longitude].to_f.round(3));
    stops = Rails.cache.fetch("#{point.to_s}/closest_stops", expires_in: 24.hours) do
      Stop.in_lviv.within(accuracy.to_f / 1000 * 2, origin: point).by_distance(origin: point).map{|stop| {code: stop.code, name: stop.name, longitude: stop.longitude, latitude: stop.latitude} }
    end

    render json: stops
  end

end
