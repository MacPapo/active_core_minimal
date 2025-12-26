class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :member, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :sale, null: false, foreign_key: true

      t.date :start_date, null: false
      t.date :end_date, null: false

      t.integer :suspension_days_count, default: 0, null: false

      t.datetime :discarded_at, index: true
      t.timestamps
    end

    add_index :subscriptions, [ :member_id, :end_date ]
  end
end
