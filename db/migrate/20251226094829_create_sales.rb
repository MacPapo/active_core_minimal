class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.references :member, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.string :product_name_snapshot, null: false

      t.integer :amount_cents, default: 0, null: false
      t.integer :payment_method, default: 0, null: false

      t.date :sold_on, null: false
      t.text :notes

      t.string :receipt_sequence
      t.integer :receipt_number
      t.integer :receipt_year
      t.virtual :receipt_code, type: :string,
                as: "receipt_year || '-' || receipt_sequence || '-' || receipt_number",
                stored: true

      t.datetime :discarded_at, index: true
      t.timestamps
    end

    add_index :sales, [ :receipt_year, :receipt_sequence, :receipt_number ],
              unique: true,
              where: "receipt_number IS NOT NULL"

    add_index :sales, :receipt_code
    add_index :sales, :sold_on
  end
end
