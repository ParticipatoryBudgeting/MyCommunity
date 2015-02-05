class ExpendV2Causes < ActiveRecord::Migration
  def self.up
    add_column :causes, :target_group, :string
    add_column :causes, :status, :string
  end

  def self.down
    remove_column :causes, :target_group
    remove_column :causes, :status
  end
end
