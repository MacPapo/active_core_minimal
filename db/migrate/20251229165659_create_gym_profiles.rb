class CreateGymProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :gym_profiles do |t|
      t.string :name
      t.string :address_line_1
      t.string :address_line_2
      t.string :zip_code
      t.string :city
      t.string :vat_number
      t.string :email
      t.string :phone
      t.string :bank_iban

      t.timestamps
    end
  end
end
