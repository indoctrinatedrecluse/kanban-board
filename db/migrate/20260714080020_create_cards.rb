class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.references :column, null: false, foreign_key: true
      t.references :assignee, null: true, foreign_key: { to_table: :users }
      t.string :title
      t.text :description
      t.string :priority
      t.date :due_on
      t.integer :estimate
      t.integer :position
      t.string :labels

      t.timestamps
    end
  end
end
