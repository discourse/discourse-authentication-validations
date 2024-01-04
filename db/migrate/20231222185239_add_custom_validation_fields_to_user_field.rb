# frozen_string_literal: true

class AddCustomValidationFieldsToUserField < ActiveRecord::Migration[7.0]
  def change
    add_column :user_fields, :has_custom_validation, :boolean, default: false, null: false
    add_column :user_fields, :show_values, :text, array: true, default: []
    add_column :user_fields, :target_user_field_ids, :bigint, array: true, default: []
  end
end
