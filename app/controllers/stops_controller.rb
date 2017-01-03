class StopsController < ApplicationController

  # GET /stops
  # GET /stops.json
  def index
    @stops = Stop.in_lviv.order(name: :asc)
  end

  # GET /stops/1
  # GET /stops/1.json
  def show

  end

  def closest

  end

end
