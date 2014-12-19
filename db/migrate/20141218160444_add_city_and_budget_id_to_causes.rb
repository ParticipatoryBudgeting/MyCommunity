class AddCityAndBudgetIdToCauses < ActiveRecord::Migration
  def self.up
    add_column :causes, :city, :string
    add_column :causes, :budget_id, :integer
  end

  def self.down
    remove_column :causes, :budget_id
    remove_column :causes, :city
  end
end
