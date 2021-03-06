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

ActiveRecord::Schema.define(version: 20170520052512) do

  create_table "custom_commands", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint "server_id", null: false
    t.string "trigger",   null: false
    t.string "output",    null: false
  end

  create_table "feeds", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint  "server_id", null: false
    t.boolean "allow",     null: false
    t.string  "modifier",  null: false
    t.bigint  "target",    null: false
  end

  create_table "members", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.bigint   "server_id",    null: false
    t.bigint   "user_id",      null: false
    t.string   "display_name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.bigint "server_id",                 null: false
    t.bigint "channel_id",                null: false
    t.bigint "user_id",                   null: false
    t.bigint "message_id",                null: false
    t.string "username",                  null: false
    t.text   "content",     limit: 65535
    t.text   "attachments", limit: 65535
  end

  create_table "moderators", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.bigint "server_id", null: false
    t.bigint "user_id",   null: false
  end

  create_table "past_nicknames", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint   "user_id",    null: false
    t.string   "nickname",   null: false
    t.datetime "created_at", null: false
  end

  create_table "past_usernames", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint   "user_id",    null: false
    t.string   "username",   null: false
    t.datetime "created_at", null: false
  end

  create_table "roles", unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.bigint "server_id", null: false, unsigned: true
    t.bigint "user_id",   null: false, unsigned: true
    t.bigint "role_id",   null: false, unsigned: true
  end

  create_table "settings", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint "server_id", null: false
    t.string "option",    null: false
    t.string "value",     null: false
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.bigint   "user_id",    null: false
    t.string   "username",   null: false
    t.string   "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
