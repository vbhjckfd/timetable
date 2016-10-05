require 'json'

class Api::StopController < ApplicationController

  def show
    stop_id = params[:id].rjust(4, '0')
    stop = Stop.where(code: stop_id).first

    render json: stop
  end

  def closest
    coords = params.slice(:longitude, :latitude)
    accuracy = params[:accuracy] || 10
    render(status: :bad_request, text: "No coordinates provided (longitude, latitude)") if coords.count != 2

    point = Geokit::LatLng.new(params[:latitude], params[:longitude])
    stops = Stop.in_lviv.within(accuracy.to_f / 1000 * 2, origin: point).by_distance(origin: point).select{|stop| stop.code.length < 5 }.slice(0, 5).map{|stop| {code: stop.code, name: stop.name, longitude: stop.longitude, latitude: stop.latitude} }

    return render(status: :not_found, text: "No stops around you: <a target='_blank' href='https://maps.google.com?q=#{coords[:latitude]},#{coords[:longitude]}'>#{coords[:latitude]}, #{coords[:longitude]}</a>") if stops.empty?

    render json: stops
  end

  def timetable
    stop_id = params[:stop_id].rjust(4, '0')
    stop = Stop.where(code: stop_id).first

    return render(status: :bad_request, text: "No stop with code #{stop_id}") unless stop

    @response = stop.get_timetable

    case params[:format]
      when 'xml'
        render xml: @response
      else
        render json: @response
    end

  end

end
