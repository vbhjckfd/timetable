class Stop < ActiveRecord::Base

  TIMETABLE_API_CALL = 'https://api.eway.in.ua/?login=lad.lviv&password=k3NhsvwLDai2ne9fn&function=stops.GetStopInfo&city=lviv&id=%{code}&v=1.2'

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
    all_info = Rails.cache.fetch("stop_timetable/#{self.id}", expires_in: 15.seconds) do
      self.get_timetable_from_api
    end
  end

  def get_timetable_from_api
    timetable = []

    url = TIMETABLE_API_CALL % {code: self.easyway_id}
    raw_data = %x(curl --max-time 30 --silent "#{url}" -H "Accept: application/json")

    begin
      data = JSON.parse(raw_data).symbolize_keys![:routes]
    rescue JSON::ParserError => e
      data = []
    end
    data ||= []

    data = data.map {|i| i.symbolize_keys!}
    data.select! { |s| s[:timeSource] == 'gps' }
    data.sort! { |a,b| a[:timeLeft] <=> b[:timeLeft] }

    directions = {};

    data.slice(0, 10).each do |item|
      vehicle_type = case
        when item[:transportKey] == 'trol'
          :trol
        when item[:transportKey] == 'tram'
          :tram
        else
          :bus
      end

      prefix = 'A'
      prefix = 'T' if (['trol', 'tram'].include?(item[:transportKey]))

      directions[item[:id]] = item[:directionTitle] unless directions.key? item[:id]

      timetable << {
        route: prefix + item[:title],
        vehicle_type: vehicle_type,
        lowfloor: item[:handicapped],
        end_stop: directions[item[:id]],
        time_left: item[:timeLeftFormatted],
        longitude: 0,
        latitude: 0,
        number: 0
      }
    end

    timetable
  end

end
