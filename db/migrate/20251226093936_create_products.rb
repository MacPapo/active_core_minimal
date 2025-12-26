class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false

      t.integer :price_cents, default: 0, null: false
      t.integer :duration_days, null: false
      t.string :accounting_category, default: "institutional", null: false

      t.datetime :discarded_at, index: true
      t.timestamps
    end

    add_index :products, :name, unique: true, where: "discarded_at IS NULL"
  end
end
