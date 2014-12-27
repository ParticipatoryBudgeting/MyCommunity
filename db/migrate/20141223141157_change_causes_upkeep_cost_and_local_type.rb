class ChangeCausesUpkeepCostAndLocalType < ActiveRecord::Migration
  def self.up
  	change_column :causes, :upkeep_cost, :text
  	change_column :causes, :local, :text
  end

  def self.down
  	# change_column :causes, :upkeep_cost, :string
  	# change_column :causes, :local, :string
  end
end
