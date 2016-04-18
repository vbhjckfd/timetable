require 'json'
require 'nokogiri'

class Api::StopController < ApplicationController

  TIMETABLE_API_CALL = 'http://82.207.107.126:13541/SimpleRIDE/%{company_name}/SM.WebApi/api/stops/?code=%{code}'

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
      @response << {
        route: strip_route(item["RouteName"]), 
        vehicle_type: vehicle_type, 
        end_stop: item['IterationEnd'],
        seconds_left: item["TimeToPoint"], 
        time_left: round_time(item["TimeToPoint"]),
        longitude: item['X'],
        latitude: item['Y'],
      }
    end

    case params[:format]
      when 'xml' 
        render xml: @response
      else 
        render json: @response
    end
    
  end


  private

  def strip_route(title)
    title.gsub(/\D/, '')
  end

  def round_time(time)
    time = Time.at(time).utc
    return '< 1 хв' if time.to_i < 31

    disp_time = time + (time.sec > 30 ? 1 : 0).minute
    disp_time.strftime("%-M хв")
  end


end
