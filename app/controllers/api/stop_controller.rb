require 'json'
require 'nokogiri'

class Api::StopController < ApplicationControllerApi

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

    data.slice(0, 5).each do |item|
        @response << {route: item["RouteName"], time_left: Time.at(item["TimeToPoint"]).utc.strftime("%-Mm %Ss")}
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
