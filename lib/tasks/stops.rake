require 'protobuf'
require 'google/transit/gtfs-realtime.pb'
require 'net/http'
require 'uri'
require 'csv'
require 'open-uri'
require 'zip'

namespace :stops do

  class String
    def trimzero
      self.sub(/^[0:]*/, "")
    end
  end

  def get_data_from(url)
    data = Net::HTTP.get(URI.parse(url))
    feed = Transit_realtime::FeedMessage.decode(data)
  end

  def map_stops
    Stop.all.each do |s|
      s.easyway_id = nil
      s.save
    end

    easy_way_stops = CSV.read("lviv-stops.csv", quote_char: "|", col_sep: ";")[1 .. -1].each do |row|
      easyway_stop = Geokit::LatLng.new(row[1],row[2])
      closest = Stop.closest(origin: easyway_stop).first

      next if closest.distance_from(easyway_stop) > 0.1
      closest.easyway_id = row[0]
      closest.save
    end

  end

  def import_stop(row)
    # {:stop_id=>"5129", :stop_code=>"153", :stop_name=>"\xD0\x90\xD0\xB5\xD1\x80\xD0\xBE\xD0\xBF\xD0\xBE\xD1\x80\xD1\x82", :stop_desc=>nil, :stop_lat=>"49.812833637475", :stop_lon=>"23.96170735359192", :zone_id=>"lviv_city", :stop_url=>nil, :location_type=>"0", :parent_station=>nil, :stop_timezone=>nil, :wheelchair_boarding=>"0"}
    row[:stop_name] = row[:stop_name].force_encoding("UTF-8")

    return if row[:stop_code].nil?
    row[:stop_code] = row[:stop_code].trimzero

    # begin
    #   Integer(row[:stop_code])
    # rescue
    #   p "Code #{row[:stop_code]} for #{row[:stop_name]} is bad value"
    #   return
    # end

    stop = Stop.find_or_initialize_by(code: row[:stop_code])

    stop.external_id = row[:stop_id]
    stop.code = row[:stop_code]
    stop.name = row[:stop_name]
    stop.longitude = row[:stop_lon]
    stop.latitude = row[:stop_lat]
    stop.save

    #p [stop.code, stop.name]
  end

  def import_route(row)
    # {:route_id=>"1002", :agency_id=>"52", :route_short_name=>"\xD0\x9005", :route_long_name=>"\xD0\x9C\xD0\xB0\xD1\x80\xD1\x88\xD1\x80\xD1\x83\xD1\x82 \xE2\x84\x96\xD0\x9005 (\xD0\xBC. \xD0\x92\xD0\xB8\xD0\xBD\xD0\xBD\xD0\xB8\xD0\xBA\xD0\xB8 - \xD0\xBF\xD0\xBB. \xD0\xA0\xD1\x96\xD0\xB7\xD0\xBD\xD1\x96)-\xD1\x80\xD0\xB5\xD0\xBC", :route_type=>"3", :route_desc=>nil, :route_url=>nil, :route_color=>nil, :route_text_color=>nil}

    route = Route.find_or_initialize_by(external_id: row[:route_id])
    route.name = row[:route_long_name].force_encoding("UTF-8")
    row[:route_short_name] = row[:route_short_name].force_encoding("UTF-8")

    route.vehicle_type = case row[:route_type]
      when '0'
        :tram
      when '3'
        route.name.start_with?('Маршрут №Тр') ? :trol : :bus
      else
        :bus
    end

    route.save
    #p [route.name, row[:route_short_name]]
  end

  def import_route_stops(stops_per_route)
    stops_per_route.each do |route_id, stops|
      route = Route.find_by(external_id: route_id)
      route.stops.clear
      route.stops = []

      stops.each do |stop_id|
        stop = Stop.find_by(external_id: stop_id)
        route.stops << stop if stop
      end

      p route.name
    end
  end

  def import_gtfs_static
    content = open('http://track.ua-gis.com/iTrack/conn_apps/gtfs/static/get')
    # content = open('/Users/mholyak/Downloads/feed.zip')

    Zip::File.open_buffer(content) do |zip|
      data = {
        trips: {},
        stop_times: {},
      }

      zip.each do |entry|
        content = entry.get_input_stream.read

        CSV.parse(content, headers: true) do |row|
          row = row.to_hash.symbolize_keys

          case entry.name
          when 'stops.txt'
            import_stop row
          when 'routes.txt'
            import_route row
          when 'trips.txt'
            data[:trips][row[:trip_id]] = row[:route_id]
          when 'stop_times.txt'
            data[:stop_times][row[:trip_id]] = {} unless data[:stop_times].has_key? row[:trip_id]
            data[:stop_times][row[:trip_id]][row[:stop_id]] = true
          end
        end
      end

      routes_stops = {}
      data[:stop_times].each do |trip_id, stops|
        route_id = data[:trips][trip_id]
        next if routes_stops.has_key? route_id

        routes_stops[route_id] = stops.keys
      end

      data = nil # Save as much memory as we can

      import_route_stops routes_stops
    end
  end

  # def import_vehicle_position
  #   feed = get_data_from "http://track.ua-gis.com/iTrack/conn_apps/gtfs/realtime/vehicle_position"
  #   for entity in feed.entity do
  #     p entity.vehicle
  #     #p "#{entity.vehicle.vehicle.id} => [#{entity.vehicle.position.longitude}, #{entity.vehicle.position.latitude}]"
  #   end
  # end

  # desc "Map stops from EasyWay"
  # task map_from_easyway: :environment do
  #   map_stops
  # end

  desc "Import stops from Microgiz"
  task import_gtfs_static: :environment do
    import_gtfs_static
  end

  # desc "Import transport location"
  # task vehicle_position: :environment do
  #   import_vehicle_position
  # end

end
