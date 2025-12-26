class CreateReceiptCounters < ActiveRecord::Migration[8.1]
  def change
    create_table :receipt_counters do |t|
      t.integer :year, null: false
      t.string :sequence_category, null: false
      t.integer :last_number, default: 0, null: false

      t.timestamps
    end

    add_index :receipt_counters, [ :year, :sequence_category ], unique: true
  end
end
