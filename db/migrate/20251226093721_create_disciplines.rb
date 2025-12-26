class CreateDisciplines < ActiveRecord::Migration[8.1]
  def change
    create_table :disciplines do |t|
      t.string :name, null: false

      t.boolean :requires_medical_certificate, default: true, null: false
      t.boolean :requires_membership, default: true, null: false

      t.datetime :discarded_at, index: true
      t.timestamps
    end
    add_index :disciplines, :name, unique: true, where: "discarded_at IS NULL"
  end
end
