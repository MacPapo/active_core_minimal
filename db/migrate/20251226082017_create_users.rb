class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false

      t.string :username, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.virtual :full_name, type: :string, as: "first_name || ' ' || last_name", stored: true

      t.integer :role, default: 0, null: false

      t.json :preferences, default: {}, index: true

      t.datetime :discarded_at, index: true
      t.timestamps
    end
    add_index :users, :email_address, unique: true, where: "discarded_at IS NULL"
    add_index :users, :username, unique: true, where: "discarded_at IS NULL"
    add_index :users, :role
  end
end
