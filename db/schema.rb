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

ActiveRecord::Schema.define(version: 20160122174233) do

  create_table "documents", force: :cascade do |t|
    t.integer  "download_id"
    t.integer  "download_status", default: 0
    t.string   "document_id"
    t.string   "filename"
    t.string   "doc_type"
    t.string   "source"
    t.string   "mime_type"
    t.datetime "received_at"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "documents", ["download_id"], name: "index_documents_on_download_id"

  create_table "downloads", force: :cascade do |t|
    t.string   "request_id"
    t.string   "file_number"
    t.integer  "status",      default: 0
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

end
