# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180717182835) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "documents", force: :cascade do |t|
    t.integer "download_id"
    t.integer "download_status", default: 0
    t.string "document_id"
    t.string "vbms_filename"
    t.string "source"
    t.string "mime_type"
    t.datetime "received_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "lock_version"
    t.string "type_description"
    t.string "type_id"
    t.text "error_message"
    t.string "downloaded_from", default: "VBMS"
    t.string "jro"
    t.string "ssn"
    t.integer "size"
    t.integer "conversion_status"
    t.index ["completed_at"], name: "index_documents_on_completed_at"
    t.index ["download_id", "document_id"], name: "index_documents_on_download_id_and_document_id"
    t.index ["download_status"], name: "index_documents_on_download_status"
  end

  create_table "downloads", force: :cascade do |t|
    t.string "request_id"
    t.string "file_number"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version"
    t.datetime "manifest_fetched_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "veteran_last_name"
    t.string "veteran_first_name"
    t.string "veteran_last_four_ssn"
    t.integer "user_id"
    t.bigint "zipfile_size"
    t.boolean "from_api", default: false
    t.datetime "manifest_vva_fetched_at"
    t.datetime "manifest_vbms_fetched_at"
    t.index ["completed_at"], name: "downloads_completed_at"
    t.index ["file_number", "user_id"], name: "index_downloads_on_file_number_and_user_id"
    t.index ["manifest_fetched_at"], name: "downloads_manifest_fetched_at"
    t.index ["user_id"], name: "index_downloads_on_user_id"
  end

  create_table "files_downloads", force: :cascade do |t|
    t.integer "manifest_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "requested_zip_at"
    t.index ["manifest_id", "user_id"], name: "index_files_downloads_on_manifest_id_and_user_id"
    t.index ["user_id"], name: "index_files_downloads_on_user_id"
  end

  create_table "manifest_sources", force: :cascade do |t|
    t.integer "manifest_id"
    t.integer "status", default: 0
    t.string "name"
    t.datetime "fetched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "manifests", force: :cascade do |t|
    t.string "file_number"
    t.string "veteran_last_name"
    t.string "veteran_first_name"
    t.string "veteran_last_four_ssn"
    t.bigint "zipfile_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fetched_files_status", default: 0
    t.datetime "fetched_files_at"
    t.index ["file_number"], name: "index_manifests_on_file_number", unique: true
  end

  create_table "records", force: :cascade do |t|
    t.integer "manifest_source_id"
    t.integer "status", default: 0
    t.string "version_id"
    t.string "mime_type"
    t.datetime "received_at"
    t.string "type_description"
    t.string "type_id"
    t.integer "size"
    t.string "jro"
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "conversion_status", default: 0
    t.string "series_id"
    t.integer "version"
    t.datetime "upload_date"
    t.index ["manifest_source_id", "series_id"], name: "index_records_on_manifest_source_id_and_series_id"
    t.index ["version_id", "manifest_source_id"], name: "index_records_on_version_id_and_manifest_source_id", unique: true
  end

  create_table "searches", force: :cascade do |t|
    t.integer "download_id"
    t.string "file_number"
    t.integer "status", default: 0
    t.datetime "created_at"
    t.integer "user_id"
    t.index ["created_at"], name: "searches_created_at"
    t.index ["download_id"], name: "index_searches_on_download_id"
    t.index ["status", "created_at"], name: "searches_status_created_at"
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "css_id", null: false
    t.string "station_id", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vva_coachmarks_view_count", default: 0
    t.index ["css_id", "station_id"], name: "index_users_on_css_id_and_station_id"
  end

  add_foreign_key "downloads", "users"
  add_foreign_key "searches", "users"
end
