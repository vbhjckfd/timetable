class CreateJoinTableRouteStop < ActiveRecord::Migration
  def change
    create_join_table :routes, :stops do |t|
      t.index [:route_id, :stop_id]
      t.index [:stop_id, :route_id]
    end
  end
end
