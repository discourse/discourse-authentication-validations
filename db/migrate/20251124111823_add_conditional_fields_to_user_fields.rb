# frozen_string_literal: true

class AddConditionalFieldsToUserFields < ActiveRecord::Migration[7.0]
  def change
    add_column :user_fields, :conditional_fields, :jsonb, null: true, default: []
  end
end
