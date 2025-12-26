class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false

      t.references :subject, polymorphic: true, null: false
      t.json :changes_set, default: {}

      t.timestamps
    end

    add_index :activity_logs, [ :user_id, :created_at ]
  end
end
