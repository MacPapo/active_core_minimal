# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_29_165659) do
  create_table "access_logs", force: :cascade do |t|
    t.integer "checkin_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "entered_at", null: false
    t.boolean "medical_certificate_valid", default: false, null: false
    t.integer "member_id", null: false
    t.integer "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["checkin_by_user_id"], name: "index_access_logs_on_checkin_by_user_id"
    t.index ["entered_at"], name: "index_access_logs_on_entered_at"
    t.index ["member_id", "entered_at"], name: "index_access_logs_on_member_id_and_entered_at"
    t.index ["member_id"], name: "index_access_logs_on_member_id"
    t.index ["subscription_id"], name: "index_access_logs_on_subscription_id"
  end

  create_table "activity_logs", force: :cascade do |t|
    t.string "action", null: false
    t.json "changes_set", default: {}
    t.datetime "created_at", null: false
    t.integer "subject_id", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["subject_type", "subject_id"], name: "index_activity_logs_on_subject"
    t.index ["user_id", "created_at"], name: "index_activity_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "disciplines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.boolean "requires_medical_certificate", default: true, null: false
    t.boolean "requires_membership", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_disciplines_on_discarded_at"
    t.index ["name"], name: "index_disciplines_on_name", unique: true, where: "discarded_at IS NULL"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.text "admin_notes"
    t.string "browser_info"
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.string "page_url"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["status"], name: "index_feedbacks_on_status"
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "gym_profiles", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "bank_iban"
    t.string "city"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.string "vat_number"
    t.string "zip_code"
  end

  create_table "members", force: :cascade do |t|
    t.string "address"
    t.date "birth_date", null: false
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email_address"
    t.string "first_name", null: false
    t.string "fiscal_code", null: false
    t.virtual "full_address", type: :string, as: "address || ', ' || city || ' (' || zip_code || ')'", stored: true
    t.virtual "full_name", type: :string, as: "first_name || ' ' || last_name", stored: true
    t.string "last_name", null: false
    t.date "medical_certificate_expiry"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["discarded_at"], name: "index_members_on_discarded_at"
    t.index ["fiscal_code"], name: "index_members_on_fiscal_code", unique: true, where: "discarded_at IS NULL"
    t.index ["full_address"], name: "index_members_on_full_address"
    t.index ["full_name"], name: "index_members_on_full_name"
    t.index ["medical_certificate_expiry"], name: "index_members_on_medical_certificate_expiry"
  end

  create_table "product_disciplines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "discipline_id", null: false
    t.integer "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["discipline_id"], name: "index_product_disciplines_on_discipline_id"
    t.index ["product_id", "discipline_id"], name: "index_product_disciplines_on_product_id_and_discipline_id", unique: true
    t.index ["product_id"], name: "index_product_disciplines_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "accounting_category", default: "institutional", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "duration_days", null: false
    t.string "name", null: false
    t.integer "price_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["name"], name: "index_products_on_name", unique: true, where: "discarded_at IS NULL"
  end

  create_table "receipt_counters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "last_number", default: 0, null: false
    t.string "sequence_category", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["year", "sequence_category"], name: "index_receipt_counters_on_year_and_sequence_category", unique: true
  end

  create_table "sales", force: :cascade do |t|
    t.integer "amount_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "member_id", null: false
    t.text "notes"
    t.integer "payment_method", default: 0, null: false
    t.integer "product_id", null: false
    t.string "product_name_snapshot", null: false
    t.virtual "receipt_code", type: :string, as: "receipt_year || '-' || receipt_sequence || '-' || receipt_number", stored: true
    t.integer "receipt_number"
    t.string "receipt_sequence"
    t.integer "receipt_year"
    t.date "sold_on", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["discarded_at"], name: "index_sales_on_discarded_at"
    t.index ["member_id"], name: "index_sales_on_member_id"
    t.index ["product_id"], name: "index_sales_on_product_id"
    t.index ["receipt_code"], name: "index_sales_on_receipt_code"
    t.index ["receipt_year", "receipt_sequence", "receipt_number"], name: "idx_on_receipt_year_receipt_sequence_receipt_number_3689acdaf9", unique: true, where: "receipt_number IS NOT NULL"
    t.index ["sold_on"], name: "index_sales_on_sold_on"
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.date "end_date", null: false
    t.integer "member_id", null: false
    t.integer "product_id", null: false
    t.integer "sale_id", null: false
    t.date "start_date", null: false
    t.integer "suspension_days_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_subscriptions_on_discarded_at"
    t.index ["member_id", "end_date"], name: "index_subscriptions_on_member_id_and_end_date"
    t.index ["member_id"], name: "index_subscriptions_on_member_id"
    t.index ["product_id"], name: "index_subscriptions_on_product_id"
    t.index ["sale_id"], name: "index_subscriptions_on_sale_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email_address", null: false
    t.string "first_name", null: false
    t.virtual "full_name", type: :string, as: "first_name || ' ' || last_name", stored: true
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.json "preferences", default: {}
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true, where: "discarded_at IS NULL"
    t.index ["preferences"], name: "index_users_on_preferences"
    t.index ["role"], name: "index_users_on_role"
    t.index ["username"], name: "index_users_on_username", unique: true, where: "discarded_at IS NULL"
  end

  add_foreign_key "access_logs", "members"
  add_foreign_key "access_logs", "subscriptions"
  add_foreign_key "access_logs", "users", column: "checkin_by_user_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "product_disciplines", "disciplines"
  add_foreign_key "product_disciplines", "products"
  add_foreign_key "sales", "members"
  add_foreign_key "sales", "products"
  add_foreign_key "sales", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscriptions", "members"
  add_foreign_key "subscriptions", "products"
  add_foreign_key "subscriptions", "sales"
end
