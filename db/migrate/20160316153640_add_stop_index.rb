class AddStopIndex < ActiveRecord::Migration
  def change
    add_index :stops, :external_id
    add_index :stops, :code
  end
end
