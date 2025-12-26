class CreateProductDisciplines < ActiveRecord::Migration[8.1]
  def change
    create_table :product_disciplines do |t|
      t.references :product, null: false, foreign_key: true
      t.references :discipline, null: false, foreign_key: true

      t.timestamps
    end

    add_index :product_disciplines, [ :product_id, :discipline_id ], unique: true
  end
end
