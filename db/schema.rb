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

ActiveRecord::Schema.define(version: 2020_12_29_171616) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "files_downloads", force: :cascade do |t|
    t.integer "manifest_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "requested_zip_at"
    t.index ["manifest_id", "user_id"], name: "index_files_downloads_on_manifest_id_and_user_id", unique: true
    t.index ["manifest_id"], name: "index_files_downloads_on_manifest_id"
    t.index ["user_id"], name: "index_files_downloads_on_user_id"
  end

  create_table "manifest_sources", force: :cascade do |t|
    t.integer "manifest_id"
    t.integer "status", default: 0
    t.string "name"
    t.datetime "fetched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["manifest_id"], name: "index_manifest_sources_on_manifest_id"
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

  create_table "record2020s", force: :cascade do |t|
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
    t.index ["manifest_source_id", "series_id"], name: "index_record2020s_on_manifest_source_id_and_series_id"
    t.index ["version_id", "manifest_source_id"], name: "index_record2020s_on_version_id_and_manifest_source_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "css_id", null: false
    t.string "station_id", null: false
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vva_coachmarks_view_count", default: 0
    t.string "participant_id", comment: "the user BGS participant_id"
    t.datetime "last_login_at"
    t.index "upper((css_id)::text)", name: "index_users_unique_css_id", unique: true
    t.index ["css_id", "station_id"], name: "index_users_on_css_id_and_station_id"
    t.index ["last_login_at"], name: "index_users_on_last_login_at"
  end

end
