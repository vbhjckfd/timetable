require 'json'
require 'nokogiri'

class Api::StopController < ApplicationController

  TIMETABLE_API_CALL = 'http://82.207.107.126:13541/SimpleRIDE/%{company_name}/SM.WebApi/api/stops/?code=%{code}'

  def closest
    coords = params.slice(:longitude, :latitude)
    render(status: :bad_request, text: "No coordinates provided (longitude, latitude)") if coords.count != 2

    point = Geokit::LatLng.new(params[:latitude], params[:longitude])
    stop = Stop.in_lviv.within(0.05, origin: point).by_distance(origin: point).limit(1).first

    return render(status: :not_found, text: "No stop around you: <a target='_blank' href='https://maps.google.com?q=#{coords[:latitude]},#{coords[:longitude]}'>#{coords[:latitude]}, #{coords[:longitude]}</a>") if stop.nil?

    render json: {code: stop.code, name: stop.name}
  end

  def timetable
    stop_id = params[:stop_id].rjust(4, '0')

    @response = []

    data = []
    ['LAD', 'LET'].each do |item|
        url = TIMETABLE_API_CALL % {company_name: item, code: stop_id}
        raw_data = %x(curl --silent "#{url}" -H "Accept: application/xml")

        n = Nokogiri::XML(raw_data)
        begin
          data.concat JSON.parse(n.remove_namespaces!.xpath('//string').text)
        rescue JSON::ParserError => e
          
        end
    end

    return render(status: :bad_request, text: "No stop with code #{stop_id}") if data.empty?

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
      else 
        render json: @response
    end
    
  end
end
