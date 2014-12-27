class AddColumnsToCauses < ActiveRecord::Migration
  def self.up
    add_column :causes, :total_cost, :string
    add_column :causes, :upkeep_cost, :string
    add_column :causes, :area, :string
    add_column :causes, :location_precission, :integer #  ["ROOFTOP"] => 1, ["APPROXIMATE", "GEOMETRIC_CENTER"] => 2, 
  end

  def self.down
    remove_column :causes, :location_precission
    remove_column :causes, :area
    remove_column :causes, :upkeep_cost
    remove_column :causes, :total_cost
  end
end
