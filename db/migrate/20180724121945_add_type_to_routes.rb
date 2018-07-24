class AddTypeToRoutes < ActiveRecord::Migration
  def change
    add_column :routes, :vehicle_type, :string
  end
end
