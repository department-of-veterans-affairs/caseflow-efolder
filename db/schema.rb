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

ActiveRecord::Schema.define(version: 20160125220724) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",               default: 0, null: false
    t.integer  "attempts",               default: 0, null: false
    t.text     "handler",                            null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "documents", force: :cascade do |t|
    t.integer  "download_id"
    t.integer  "download_status",             default: 0
    t.string   "document_id",     limit: 255
    t.string   "filename",        limit: 255
    t.string   "filepath",        limit: 255
    t.string   "doc_type",        limit: 255
    t.string   "source",          limit: 255
    t.string   "mime_type",       limit: 255
    t.datetime "received_at"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "documents", ["download_id"], name: "index_documents_on_download_id"

  create_table "downloads", force: :cascade do |t|
    t.string   "request_id",  limit: 255
    t.string   "file_number", limit: 255
    t.integer  "status",                  default: 0
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

end
