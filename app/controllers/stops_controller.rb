class StopsController < ApplicationController
  before_action :set_stop, only: [:show]

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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stop
      @stop = Stop.find_by(code: params[:id].rjust(4, '0'))
    end
end
