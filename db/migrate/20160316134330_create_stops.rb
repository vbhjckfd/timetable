class CreateStops < ActiveRecord::Migration
  def change
    create_table :stops do |t|
      t.string :name
      t.float :longitude
      t.float :latitude
      t.integer :external_id
      t.string :code

      t.timestamps null: false
    end
  end
end
