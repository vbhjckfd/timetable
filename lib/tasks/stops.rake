require 'csv'

namespace :stops do

  class String
    def trimzero
      self.sub(/^[0:]*/, "")
    end
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

  desc "Map stops from EasyWay"
  task map_from_easyway: :environment do
    map_stops
  end

end
