require 'json'

class Api::StopController < ApplicationController

  def show
    stop_id = params[:id]
    stop = Stop.where(code: stop_id).first

    return render(status: :bad_request, text: "No stop with code #{stop_id}") unless stop

    response = stop.as_json.merge timetable: stop.get_timetable

    render json: response
  end

  def closest
    coords = params.slice(:longitude, :latitude)
    accuracy = params[:accuracy] || 10
    render(status: :bad_request, text: "No coordinates provided (longitude, latitude)") if coords.count != 2

    point = Geokit::LatLng.new(params[:latitude], params[:longitude])
    stops = Stop.in_lviv.within(accuracy.to_f / 1000 * 2, origin: point).by_distance(origin: point).slice(0, 5).map{|stop| {code: stop.code, name: stop.name, longitude: stop.longitude, latitude: stop.latitude} }

    render json: stops
  end

end
