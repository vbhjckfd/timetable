class FillRoutesWithType < ActiveRecord::Migration

  class Route < ActiveRecord::Base
  end

  def up
    Route.all.each do |r|
      type = :bus

      if r.name.start_with? 'Тр'
        type = :trol
      elsif r.name.start_with? 'Нічний'
        type = :night
      elsif r.name.start_with? 'Т'
        type = :tram
      end

      r.vehicle_type = type
      r.save
    end
  end

end
