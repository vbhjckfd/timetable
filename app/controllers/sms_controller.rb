require 'openssl'
require 'nokogiri'

class SmsController < ApplicationController

  def zadarma
    return render(status: :not_acceptable, text: 'Bad parameters') unless (params['subject'] && params['stripped-text'])

    sender_number = params['subject'].rpartition('Вхідна СМС від: ').last
    stop_number = params['stripped-text'].rpartition('Повідомлення: ').last
    stop = Stop.find_by(code: stop_number)

    # fail if any bad stop number
    return render(status: :not_acceptable, text: 'No such stop') unless stop

    # respond with sms
    timetable_per_route = {}

    stop.get_timetable.each do |item|
      item = item.with_indifferent_access
      timetable_per_route[item[:route]] ||= []
      timetable_per_route[item[:route]] << item[:time_left]
    end

    result = ''
    timetable_per_route.sort.each do |route, times|
      result << "#{route}: #{times.join(', ')}\n"
    end

    result = result.gsub(/(Т|Тр|А|Н|хв)/, {
        "Тр" => 'Tp',
        'А' => 'A',
        'Т' => 'T',
        'Н' => 'H',
        'хв' => 'm',
    }).gsub(' m', 'm')

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.request {
        xml.auth {
          xml.login Rails.application.config.sms_provider[:login]
          xml.password Rails.application.config.sms_provider[:password]
        }
        xml.message {
          xml.from "Test"
          xml.text_ {
            xml.cdata result
          }
          xml.recipient sender_number
        }
      }
    end

    raw_data = %x(curl --data '#{builder.to_xml}' "http://letsads.com/api")

    n = Nokogiri::XML(raw_data)
    begin
      send_result = n.remove_namespaces!.xpath('//name').text
    rescue JSON::ParserError => e
      send_result = false
    end

    if ('Complete' == send_result)
      render(status: :ok, text: 'Ok')
    else
      render(status: :not_acceptable, text: builder.to_xml)
    end

  end

end
