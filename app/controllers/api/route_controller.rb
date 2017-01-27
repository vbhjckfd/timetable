require 'json'

class Api::RouteController < ApplicationController

  def show
    route_id = params[:id]
    route = Route.where(external_id: route_id).first

    return render(status: :bad_request, text: "No route with id #{route_id}") unless route

    render json: route_to_json(route)
  end

  def list
    render json: Route.all.to_a.map{ |r| route_to_json(r) }
  end

  private
  def route_to_json(route)
    result = route.as_json.symbolize_keys.slice(:name, :external_id, :code)
    result[:stops] = route.stops.uniq.map{ |stop| stop.code}
    result
  end

end
