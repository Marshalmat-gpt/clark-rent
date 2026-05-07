# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running
# `bin/rails db:schema:load`. When creating a portable database, use this file
# to create the initial database.

ActiveRecord::Schema[7.2].define(version: 2026_05_07_000005) do
  enable_extension "plpgsql"

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "role", default: "tenant", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "properties", force: :cascade do |t|
    t.string "name", null: false
    t.string "address", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_properties_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name", null: false
    t.decimal "surface_area", precision: 8, scale: 2
    t.decimal "rent", precision: 10, scale: 2, null: false
    t.decimal "charges", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "property_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_rooms_on_property_id"
  end

  create_table "leases", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "room_id", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.decimal "monthly_rent", precision: 10, scale: 2, null: false
    t.decimal "monthly_charges", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "deposit", precision: 10, scale: 2, default: "0.0", null: false
    t.string "status", default: "active", null: false
    t.datetime "signed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "status"], name: "index_leases_on_room_id_and_status"
    t.index ["room_id"], name: "index_leases_on_room_id"
    t.index ["status"], name: "index_leases_on_status"
    t.index ["tenant_id"], name: "index_leases_on_tenant_id"
  end

  create_table "lease_applications", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "room_id", null: false
    t.string "status", default: "pending", null: false
    t.text "message"
    t.datetime "validated_at"
    t.bigint "validated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_lease_applications_on_room_id"
    t.index ["status"], name: "index_lease_applications_on_status"
    t.index ["tenant_id", "room_id"], name: "index_lease_applications_on_tenant_and_room", unique: true
    t.index ["tenant_id"], name: "index_lease_applications_on_tenant_id"
    t.index ["validated_by_id"], name: "index_lease_applications_on_validated_by_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "tenant_id", null: false
    t.bigint "assigned_to_id"
    t.string "category", default: "autre", null: false
    t.text "description", null: false
    t.string "status", default: "open", null: false
    t.string "priority", default: "normal", null: false
    t.jsonb "data", default: "{}"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_tickets_on_assigned_to_id"
    t.index ["property_id", "status"], name: "index_tickets_on_property_id_and_status"
    t.index ["property_id"], name: "index_tickets_on_property_id"
    t.index ["tenant_id", "status"], name: "index_tickets_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_tickets_on_tenant_id"
  end

  create_table "rent_payments", force: :cascade do |t|
    t.bigint "lease_id", null: false
    t.bigint "tenant_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "expense_amount", precision: 10, scale: 2, default: "0.0"
    t.string "status", default: "pending", null: false
    t.date "due_date", null: false
    t.date "paid_at"
    t.string "payment_method"
    t.jsonb "data", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_rent_payments_on_due_date"
    t.index ["lease_id", "due_date"], name: "index_rent_payments_on_lease_id_and_due_date", unique: true
    t.index ["lease_id"], name: "index_rent_payments_on_lease_id"
    t.index ["tenant_id", "status"], name: "index_rent_payments_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_rent_payments_on_tenant_id"
  end

  add_foreign_key "properties", "users"
  add_foreign_key "rooms", "properties"
  add_foreign_key "leases", "rooms"
  add_foreign_key "leases", "users", column: "tenant_id"
  add_foreign_key "lease_applications", "rooms"
  add_foreign_key "lease_applications", "users", column: "tenant_id"
  add_foreign_key "lease_applications", "users", column: "validated_by_id"
  add_foreign_key "tickets", "properties"
  add_foreign_key "tickets", "users", column: "tenant_id"
  add_foreign_key "tickets", "users", column: "assigned_to_id"
  add_foreign_key "rent_payments", "leases"
  add_foreign_key "rent_payments", "users", column: "tenant_id"
end
