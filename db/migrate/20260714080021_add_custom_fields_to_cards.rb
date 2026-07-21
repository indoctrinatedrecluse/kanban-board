class AddCustomFieldsToCards < ActiveRecord::Migration[8.0]
  def change
    add_column :cards, :custom_fields, :json, default: {}
  end
end