class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.virtual :full_name, type: :string, as: "first_name || ' ' || last_name", stored: true

      t.string :fiscal_code, null: false
      t.date :birth_date, null: false

      t.string :email_address
      t.string :phone

      t.string :address
      t.string :city
      t.string :zip_code
      t.virtual :full_address, type: :string,
                as: "address || ', ' || city || ' (' || zip_code || ')'",
                stored: true

      t.date :medical_certificate_expiry, index: true

      t.datetime :discarded_at, index: true
      t.timestamps
    end

    add_index :members, :fiscal_code, unique: true, where: "discarded_at IS NULL"
    add_index :members, :full_name
    add_index :members, :full_address
  end
end
