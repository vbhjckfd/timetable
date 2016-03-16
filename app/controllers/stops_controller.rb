class StopsController < ApplicationController
  before_action :set_stop, only: [:show]

  # GET /stops
  # GET /stops.json
  def index
    @stops = Stop.all
  end

  # GET /stops/1
  # GET /stops/1.json
  def show
    @timetable = get_stop_timetable @stop
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stop
      @stop = Stop.find_by(code: params[:id].rjust(4, '0'))
    end

    def get_stop_timetable(stop)
      api_host = ENV['API_HOST'] || 'lad.lviv.ua'
      url = "http://#{api_host}/api/timetable/#{stop.code}"
      JSON.parse %x(curl --silent "#{url}" -H "Accept: application/json")
    end
end
