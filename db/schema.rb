# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20171122181603) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "documents", force: :cascade do |t|
    t.integer  "download_id"
    t.integer  "download_status",  default: 0
    t.string   "document_id"
    t.string   "vbms_filename"
    t.string   "filepath"
    t.string   "source"
    t.string   "mime_type"
    t.datetime "received_at"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "lock_version"
    t.string   "type_description"
    t.string   "type_id"
    t.text     "error_message"
    t.string   "downloaded_from",  default: "VBMS"
    t.string   "jro"
    t.string   "ssn"
    t.integer  "size"
  end

  add_index "documents", ["completed_at"], name: "index_documents_on_completed_at", using: :btree
  add_index "documents", ["download_id", "document_id"], name: "index_documents_on_download_id_and_document_id", using: :btree
  add_index "documents", ["download_status"], name: "index_documents_on_download_status", using: :btree

  create_table "downloads", force: :cascade do |t|
    t.string   "request_id"
    t.string   "file_number"
    t.integer  "status",                             default: 0
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "lock_version"
    t.datetime "manifest_fetched_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string   "veteran_last_name"
    t.string   "veteran_first_name"
    t.string   "veteran_last_four_ssn"
    t.integer  "user_id"
    t.integer  "zipfile_size",             limit: 8
    t.boolean  "from_api",                           default: false
    t.datetime "vva_fetched_at"
    t.datetime "manifest_vva_fetched_at"
    t.datetime "manifest_vbms_fetched_at"
  end

  add_index "downloads", ["completed_at"], name: "downloads_completed_at", using: :btree
  add_index "downloads", ["file_number", "user_id"], name: "index_downloads_on_file_number_and_user_id", using: :btree
  add_index "downloads", ["manifest_fetched_at"], name: "downloads_manifest_fetched_at", using: :btree
  add_index "downloads", ["user_id"], name: "index_downloads_on_user_id", using: :btree

  create_table "manifest_sources", force: :cascade do |t|
    t.integer  "manifest_id"
    t.integer  "status",      default: 0
    t.string   "source"
    t.datetime "fetched_at"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "manifests", force: :cascade do |t|
    t.string   "file_number"
    t.string   "veteran_last_name"
    t.string   "veteran_first_name"
    t.string   "veteran_last_four_ssn"
    t.integer  "zipfile_size",          limit: 8
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "manifests", ["file_number"], name: "index_manifests_on_file_number", using: :btree

  create_table "records", force: :cascade do |t|
    t.integer  "manifest_source_id"
    t.integer  "status",               default: 0
    t.string   "external_document_id"
    t.string   "mime_type"
    t.datetime "received_at"
    t.string   "type_description"
    t.string   "type_id"
    t.integer  "size"
    t.string   "vva_jro"
    t.string   "vva_source"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  create_table "searches", force: :cascade do |t|
    t.integer  "download_id"
    t.string   "file_number"
    t.integer  "status",      default: 0
    t.datetime "created_at"
    t.integer  "user_id"
  end

  add_index "searches", ["created_at"], name: "searches_created_at", using: :btree
  add_index "searches", ["download_id"], name: "index_searches_on_download_id", using: :btree
  add_index "searches", ["status", "created_at"], name: "searches_status_created_at", using: :btree
  add_index "searches", ["user_id"], name: "index_searches_on_user_id", using: :btree

  create_table "user_manifests", force: :cascade do |t|
    t.integer  "manifest_id"
    t.integer  "user_id"
    t.integer  "status",      default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "user_manifests", ["manifest_id", "user_id"], name: "index_user_manifests_on_manifest_id_and_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "css_id",                                null: false
    t.string   "station_id",                            null: false
    t.string   "email"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "vva_coachmarks_view_count", default: 0
  end

  add_index "users", ["css_id", "station_id"], name: "index_users_on_css_id_and_station_id", using: :btree

  add_foreign_key "downloads", "users"
  add_foreign_key "searches", "users"
end
