class CreateBudgets < ActiveRecord::Migration
  def self.up
    create_table :budgets do |t|
      t.string :name
      t.string :type
      t.date :from
      t.date :to
      t.integer :participants_count
      t.decimal :value

      t.timestamps
    end
  end

  def self.down
    drop_table :budgets
  end
end
