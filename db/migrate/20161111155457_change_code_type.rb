class ChangeCodeType < ActiveRecord::Migration

  def change
    change_column :stops, :code, :integer
  end

  def down
    change_column :stops, :code, :string
  end
end
