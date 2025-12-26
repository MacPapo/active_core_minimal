class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.text :message, null: false
      t.string :page_url        # Es: "/members/104/edit"
      t.string :browser_info    # Es: "Chrome 120 on Windows" (ex user_agent)
      t.integer :status, default: 0, null: false

      t.text :admin_notes       # "Risolto aggiornando la gemma X"

      t.timestamps
    end

    add_index :feedbacks, :status
  end
end
