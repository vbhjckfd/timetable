class Stop < ActiveRecord::Base

  acts_as_mappable :default_units => :kms,
                   :default_formula => :sphere,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  scope :in_lviv, -> {
    ne = Geokit::LatLng.new(49.909403,24.178282)
    sw = Geokit::LatLng.new(49.760845,23.838736)
    in_bounds([sw, ne])
  }

end
