require 'json'
require 'nokogiri'

class Api::StopController < ApplicationControllerApi

  include Api::StopHelper

  TIMETABLE_API_CALL = 'http://82.207.107.126:13541/SimpleRIDE/%{company_name}/SM.WebApi/api/stops/?code=%{code}'

  def timetable
    stop_id = params[:stop_id].rjust(4, '0')

    @response = []

    data = []
    ['LAD', 'LET'].each do |item|
        url = TIMETABLE_API_CALL % {company_name: item, code: stop_id}
        raw_data = %x(curl --silent "#{url}" -H "Accept: application/xml")

        n = Nokogiri::XML(raw_data)
        data.concat JSON.parse(n.remove_namespaces!.xpath('//string').text)
    end

    data.sort! { |a,b| a['TimeToPoint'] <=> b['TimeToPoint'] }

    data.slice(0, 10).each do |item|
      vehicle_type = case
      when item['RouteName'].start_with?('Трамвай')
        :tram
      when item['RouteName'].start_with?('Тролейбус')
        :trol
      else
        :bus
      end
      @response << {route: item["RouteName"], vehicle_type: vehicle_type, end_stop: item['IterationEnd'], seconds_left: item["TimeToPoint"]}
    end

    case params[:format]
      when 'xml' 
        render xml: @response
      when 'html'
        render 'api/stop/timetable'
      else 
        render json: @response
    end
    
  end
end
