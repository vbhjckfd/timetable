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
    stop = Stop.where(code: stop_id).first

    return render(status: :bad_request, text: "No stop with code #{stop_id}") unless stop

    @response = []

    
    url = TIMETABLE_API_CALL % {company_name: 'LAD', code: stop_id}
    raw_data = %x(curl --max-time 3 --silent "#{url}" -H "Accept: application/xml")

    n = Nokogiri::XML(raw_data)
    begin
      data = JSON.parse(n.remove_namespaces!.xpath('//string').text)
    rescue JSON::ParserError => e
      data = []
    end

    data.sort! { |a,b| a['TimeToPoint'] <=> b['TimeToPoint'] }

    data.slice(0, 10).each do |item|
      vehicle_type = case
      when item['RouteName'].start_with?('ЛАД Тр')
        :trol        
      when item['RouteName'].start_with?('ЛАД Т')
        :tram
      else
        :bus
      end
      @response << {
        route: strip_route(item["RouteName"]), 
        full_route_name: item["RouteName"],
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
    title.gsub(/^ЛАД\s/, '').gsub(/^(А|Тр|Т|Н)(\d{1,2})(.+)/, '\1\2')
  end

  def round_time(time)
    time = Time.at(time).utc
    return '< 1 хв' if time.to_i < 31

    disp_time = time + (time.sec > 30 ? 1 : 0).minute
    disp_time.strftime("%-M хв")
  end


end
