class SmsController < ApplicationController

  def get
    xml_doc  = Nokogiri::XML(request.raw_post).remove_namespaces!
    stop_code = xml_doc.xpath('//body').text

    url = "https://lad.lviv.ua/api/stops/%{code}" % {code: stop_code}

    raw_data = %x(curl --max-time 30 --silent "#{url}")
    begin
      stop_data = JSON.parse raw_data, symbolize_names: true
    rescue => ex
      return render :nothing => true, :status => :service_unavailable
    end

    timetable = {};
    stop_data[:timetable].each do |item|
      timetable[item[:route]] = [] unless timetable.key? item[:route]

      timetable[item[:route]] << item[:time_left] if timetable[item[:route]].length < 2
    end

    result = []
    timetable.each do |key, row|
      joined_times = row.join(', ').gsub(/хв/, 'm')
      result << "#{key}: #{joined_times}"
    end

    while result.join("\n").length > 160
      result.pop
    end

    result.sort! do |x, y|
      x[0..3] <=> y[0..3]
    end

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.answer(:type => 'sync') {
        xml.body(:paid => false) {
          xml.cdata(result.join "\n")
        }
      }
    end

    render :text => builder.to_xml, :content_type => 'application/xml'
  end

end
