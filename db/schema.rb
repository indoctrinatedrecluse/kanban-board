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

ActiveRecord::Schema[8.1].define(version: 2026_07_14_080020) do
  create_table "boards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "cards", force: :cascade do |t|
    t.integer "assignee_id"
    t.integer "column_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_on"
    t.integer "estimate"
    t.string "labels"
    t.integer "position"
    t.string "priority"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_cards_on_assignee_id"
    t.index ["column_id"], name: "index_cards_on_column_id"
  end

  create_table "columns", force: :cascade do |t|
    t.integer "board_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.integer "wip_limit"
    t.index ["board_id"], name: "index_columns_on_board_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "cards", "columns"
  add_foreign_key "cards", "users", column: "assignee_id"
  add_foreign_key "columns", "boards"
end
