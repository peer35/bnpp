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

ActiveRecord::Schema[8.1].define(version: 2025_09_10_100247) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "document_id"
    t.string "document_type"
    t.binary "title"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id", null: false
    t.string "user_type"
    t.index ["document_id"], name: "index_bookmarks_on_document_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "records", id: :serial, force: :cascade do |t|
    t.text "achtergrond"
    t.text "autopsie"
    t.text "biblio"
    t.string "bnpp_id"
    t.text "categorie"
    t.datetime "created_at", precision: nil, null: false
    t.text "drukker"
    t.text "eigenaar"
    t.text "formaat"
    t.text "fotos"
    t.text "frequentie"
    t.text "literatuur"
    t.text "medewerkers"
    t.string "notitie"
    t.text "omvang"
    t.text "ondertitel"
    t.text "oplage"
    t.text "prijzen"
    t.text "redactie"
    t.text "speciale"
    t.text "tekeningen"
    t.text "titel"
    t.text "uitgave"
    t.text "uitgever"
    t.datetime "updated_at", precision: nil, null: false
    t.string "user_email"
    t.text "verschenen"
    t.text "vindplaats"
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.binary "query_params"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.string "user_type"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "guest", default: false
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "event", null: false
    t.integer "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end
end
