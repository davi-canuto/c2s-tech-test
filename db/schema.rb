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

ActiveRecord::Schema[8.0].define(version: 2025_12_02_124037) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.string "product_code"
    t.string "email_subject"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["created_at"], name: "index_customers_on_created_at"
    t.index ["discarded_at"], name: "index_customers_on_discarded_at"
    t.index ["email"], name: "index_customers_on_email"
  end

  create_table "medias", force: :cascade do |t|
    t.string "filename"
    t.bigint "file_size"
    t.string "content_type"
    t.string "checksum"
    t.string "sender"
    t.string "subject"
    t.datetime "original_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["checksum"], name: "index_medias_on_checksum", unique: true
    t.index ["discarded_at"], name: "index_medias_on_discarded_at"
  end

  create_table "parser_records", force: :cascade do |t|
    t.string "filename", null: false
    t.string "sender"
    t.string "parser_used"
    t.integer "status", default: 0, null: false
    t.jsonb "extracted_data", default: {}
    t.text "error_message"
    t.bigint "customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "media_id"
    t.datetime "discarded_at"
    t.index ["created_at"], name: "index_parser_records_on_created_at"
    t.index ["customer_id"], name: "index_parser_records_on_customer_id"
    t.index ["discarded_at"], name: "index_parser_records_on_discarded_at"
    t.index ["media_id"], name: "index_parser_records_on_media_id"
    t.index ["sender"], name: "index_parser_records_on_sender"
    t.index ["status"], name: "index_parser_records_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "parser_records", "customers"
  add_foreign_key "parser_records", "medias"
end
