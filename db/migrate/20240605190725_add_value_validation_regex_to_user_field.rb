# frozen_string_literal: true

class AddValueValidationRegexToUserField < ActiveRecord::Migration[7.0]
  def change
    add_column :user_fields, :value_validation_regex, :string, default: "", null: true
  end
end
