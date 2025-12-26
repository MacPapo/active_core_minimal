class CreateAccessLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :access_logs do |t|
      t.references :member, null: false, foreign_key: true
      t.references :subscription, null: false, foreign_key: true

      t.references :checkin_by_user, null: false, foreign_key: { to_table: :users }

      t.datetime :entered_at, null: false
      t.boolean :medical_certificate_valid, default: false, null: false

      t.timestamps
    end

    add_index :access_logs, :entered_at
    add_index :access_logs, [ :member_id, :entered_at ]
  end
end
