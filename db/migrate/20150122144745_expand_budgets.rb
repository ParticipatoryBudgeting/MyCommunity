class ExpandBudgets < ActiveRecord::Migration
  def self.up
    add_column :budgets, :edit_number, :integer
    add_column :budgets, :city, :string
    add_column :budgets, :initiator, :string
    add_column :budgets, :reason, :text
    add_column :budgets, :creation_date, :date
    add_column :budgets, :decision, :string
    add_column :budgets, :evaluation, :string
    add_column :budgets, :recomendation, :text
    add_column :budgets, :locked, :boolean
    add_column :budgets, :preparation_date, :date
  end

  def self.down
    remove_column :budgets, :edit_number
    remove_column :budgets, :city;
    remove_column :budgets, :initiator
    remove_column :budgets, :reason;
    remove_column :budgets, :creation_date;
    remove_column :budgets, :decision;
    remove_column :budgets, :evaluation;
    remove_column :budgets, :recomendation;
    remove_column :budgets, :locked;
    remove_column :budgets, :preparation_date
  end
end
