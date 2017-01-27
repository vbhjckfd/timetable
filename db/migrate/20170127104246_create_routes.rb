class CreateRoutes < ActiveRecord::Migration
  def change
    create_table :routes do |t|
      t.string :name
      t.string :code
      t.string :external_id
      t.references :stops, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
