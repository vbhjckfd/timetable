class SmsController < ApplicationController

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  def get
    xml_doc  = Nokogiri::XML(request.raw_post).remove_namespaces!
    stop_code = xml_doc.xpath('//body').text

    stop = Stop.where(code: stop_code).first
    return render :nothing => true, :status => :service_unavailable unless stop

    timetable = {};
    stop.get_timetable.each do |item|
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

    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.answer(:type => 'sync') {
        xml.body(:paid => false) {
          xml.cdata(result.join "\n")
        }
      }
    end

    render :text => builder.to_xml, :content_type => 'application/xml'
  end

end
