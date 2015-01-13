class AddMarkerToCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :marker, :string
  end

  def self.down
    add_column :categories, :marker, :string
  end
end
