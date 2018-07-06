class AddEasyWayIdToStops < ActiveRecord::Migration
  def change
    add_column :stops, :easyway_id, :int
  end
end
