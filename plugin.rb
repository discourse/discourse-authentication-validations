# frozen_string_literal: true

# name: discourse-authentication-validations
# about: Add custom validations to a User Field to toggle the display of User Fields based on the Signup Modal. This allows you to "chain" User Fields together, so that a User Field is only displayed if a previous User Field has a specific value.
# meta_topic_id: 292547
# version: 0.0.1
# authors: Discourse
# url: TODO
# required_version: 2.7.0

enabled_site_setting :discourse_authentication_validations_enabled

register_asset "stylesheets/common/admin/common.scss"

module ::DiscourseAuthenticationValidations
  PLUGIN_NAME = "discourse-authentication-validations"
end

require_relative "lib/discourse_authentication_validations/engine"

after_initialize do
  class ::DiscourseAuthenticationValidations::Current < ActiveSupport::CurrentAttributes
    attribute :user_fields_params
  end

  add_to_serializer(:user_field, :has_custom_validation) { object.has_custom_validation }
  add_to_serializer(:user_field, :show_values) { object.show_values }
  add_to_serializer(:user_field, :target_user_field_ids) { object.target_user_field_ids }
  add_to_serializer(:user_field, :value_validation_regex) { object.value_validation_regex }

  register_modifier(:admin_user_fields_columns) do |columns|
    columns.push(
      :has_custom_validation,
      :show_values,
      :target_user_field_ids,
      :value_validation_regex,
    )
    columns
  end

  # Add helper method for UserField - check if field should be hidden
  class ::UserField
    def should_be_hidden?
      # Get user_fields_params from CurrentAttributes
      user_fields_params = DiscourseAuthenticationValidations::Current.user_fields_params
      return false unless user_fields_params.present?

      # Find all parent fields that have THIS field (self) in target_user_field_ids
      parent_fields = UserField.where("? = ANY(target_user_field_ids)", self.id)

      # If no parent fields with custom validation - field is not hidden
      return false if parent_fields.empty?

      parent_fields.any? do |parent_field|
        # Skip if parent doesn't have custom validation
        next unless parent_field.has_custom_validation

        # Get parent field value from user_fields_params
        parent_value = user_fields_params[parent_field.id.to_s]

        # If parent field value is NOT in show_values - field should be hidden
        !parent_field.show_values.include?(parent_value.to_s)
      end
    end
  end

  # Minimally invasive UsersController patch via prepend
  module UsersControllerHiddenFieldsPatch
    def create
      # Save user_fields to CurrentAttributes (automatically cleaned up after request)
      if params[:user_fields].present?
        DiscourseAuthenticationValidations::Current.user_fields_params = params[:user_fields]
        Rails.logger.info("[discourse-authentication-validations] Saved user_fields for validation")
      end

      # Call original method
      super
    end
  end

  # Patch UserField#required? to check should_be_hidden
  class ::UserField
    alias_method :original_required?, :required?

    def required?
      # If field should be hidden - ignore required
      if should_be_hidden?
        return false
      end

      # Otherwise use original method
      original_required?
    end
  end

  require_dependency 'users_controller'
  ::UsersController.prepend(UsersControllerHiddenFieldsPatch)
end
