require 'csv'

namespace :stops do

  class String
    def trimzero
      self.sub(/^[0:]*/, "")
    end
  end

  def map_stops
    easy_way_stops = CSV.read("lviv-stops.csv", quote_char: "|", col_sep: ";")[1 .. -1].each do |row|
      easyway_stop = Geokit::LatLng.new(row[1],row[2])
      closest = Stop.closest(origin: easyway_stop).first

      closest.easyway_id = row[0]
      closest.save
    end

  end

  desc "Map stops from EasyWay"
  task map_from_easyway: :environment do
    map_stops
  end

end
