class StopsController < ApplicationController

  # GET /stops
  # GET /stops.json
  def index
    @stops = Stop.in_lviv.order(name: :asc)
  end

  # GET /stops/1
  # GET /stops/1.json
  def show
    params[:id].sub!(/^[0:]*/,"") if params[:id].start_with?('0')

    @stop = Stop.find_by(code: params[:id])
  end

  def closest

  end

end
