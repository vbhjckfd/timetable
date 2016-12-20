require 'nokogiri'

class Stop < ActiveRecord::Base

  TIMETABLE_API_CALL = 'http://82.207.107.126:13541/SimpleRIDE/LAD/SM.WebApi/api/stops/?code=%{code}'

  acts_as_mappable :default_units => :kms,
                   :default_formula => :flat,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  scope :in_lviv, -> {
    ne = Geokit::LatLng.new(49.909403,24.178282)
    sw = Geokit::LatLng.new(49.760845,23.838736)
    in_bounds([sw, ne])
  }

  def get_timetable
    timetable = []

    url = TIMETABLE_API_CALL % {code: self.code.to_s.rjust(4, '0')}
    raw_data = %x(curl --max-time 30 --silent "#{url}" -H "Accept: application/xml")

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

      # Ugly, but it looks like data from API is 30sec late from reality
      item["TimeToPoint"] = item["TimeToPoint"] - 30;
      item["TimeToPoint"] = 0 if item["TimeToPoint"] < 0

      timetable << {
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

    timetable
  end

  private

  def strip_route(title)
    title.gsub(/^ЛАД\s/, '').gsub(/^(А|Тр|Т|Н)(\d{1,2})(.+)/, '\1\2').gsub(/^(\D)0(\d{1,2})$/, '\1\2')
  end

  def round_time(time)
    time = Time.at(time).utc
    return '< 1 хв' if time.to_i < 31

    disp_time = time + (time.sec > 30 ? 1 : 0).minute
    disp_time.strftime("%-M хв")
  end

end
