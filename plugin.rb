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
  add_to_serializer(:user_field, :conditional_fields) { object.conditional_fields }

  register_modifier(:admin_user_fields_columns) do |columns|
    columns.push(
      :has_custom_validation,
      :show_values,
      :target_user_field_ids,
      :value_validation_regex,
      :conditional_fields,
    )
    columns
  end

  # Add helper method for UserField - check if field should be hidden
  class ::UserField
    def should_be_hidden?
      # Get user_fields_params from CurrentAttributes
      user_fields_params = DiscourseAuthenticationValidations::Current.user_fields_params
      return false unless user_fields_params.present?

      # First, try to find parent fields that reference THIS field (self)
      # via `conditional_fields` (new format). We prefer this because it's the
      # newer authorable rules format. Only if none are found do we fall back
      # to the legacy `target_user_field_ids` array lookup.
      parent_fields = UserField.all.select do |pf|
        cf = pf.conditional_fields
        next false unless cf.present?

        if cf.is_a?(Array)
          cf.any? { |rule| Array(rule["target_user_field_ids"] || rule[:target_user_field_ids]).map(&:to_i).include?(self.id) }
        elsif cf.is_a?(Hash)
          cf.values.any? { |v| Array(v).map(&:to_i).include?(self.id) }
        else
          false
        end
      end

      # If no parents found via conditional_fields, fall back to legacy array search
      if parent_fields.empty?
        parent_fields = UserField.where("? = ANY(target_user_field_ids)", self.id)
      end

      # If no parent fields with custom validation - field is not hidden
      return false if parent_fields.empty?

      # Determine whether we should operate in conditional_fields mode.
      # If at least one parent defines non-empty conditional_fields, we use
      # conditional_fields logic for ALL parents (do not mix with legacy).
      use_conditional = parent_fields.any? { |pf| pf.respond_to?(:conditional_fields) && Array(pf.conditional_fields).any? }

      if use_conditional
        # Only consider parents that have conditional_fields defined (non-empty)
        parents_to_check = parent_fields.select { |pf| pf.respond_to?(:conditional_fields) && Array(pf.conditional_fields).any? }

        parents_to_check.any? do |parent_field|
          parent_value = user_fields_params[parent_field.id.to_s]
          mapping = parent_field.conditional_fields

          if mapping.is_a?(Array)
            matched_rules = mapping.select do |rule|
              sv = rule["show_values"] || rule[:show_values] || rule["show_value"] || rule[:show_value]
              next false unless sv.present?
              Array(sv).map(&:to_s).include?(parent_value.to_s)
            end

            if matched_rules.any?
              ids = matched_rules.flat_map { |r| Array(r["target_user_field_ids"] || r[:target_user_field_ids]) }.map(&:to_i)
              next !(ids.include?(self.id))
            else
              # If parent has conditional_fields but no rule matches this parent_value,
              # treat as hidden (do not fall back to legacy mapping when operating in
              # conditional_fields mode to avoid mixing behaviors).
              next true
            end
          else
            # mapping is a hash (legacy mapping stored in conditional_fields)
            ids_for_value = mapping[parent_value.to_s]
            if ids_for_value.present?
              next !(ids_for_value.map(&:to_i).include?(self.id))
            else
              # No mapping for this value -> treat as hidden under conditional mode
              next true
            end
          end
        end
      else
        # Legacy mode: check parent.show_values and target_user_field_ids as before
        parent_fields.any? do |parent_field|
          parent_value = user_fields_params[parent_field.id.to_s]
          !parent_field.show_values.include?(parent_value.to_s)
        end
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

  # Normalize admin params for conditional_fields so numeric-keyed hashes
  # like {"0"=>{...}, "1"=>{...}} become arrays before the controller
  # assigns them to the model. This keeps JSONB as an array.
  begin
    # correct path for the admin controller in Discourse
    require_dependency 'admin/user_fields_controller'

    module AdminUserFieldsParamsPatch
      def create
        normalize_conditional_fields_param
        super
      end

      def update
        normalize_conditional_fields_param
        super
      end

      private

      def normalize_conditional_fields_param
        begin
          uf = params[:user_field] || params[:user_fields]
          # TEMP DEBUG: log whether conditional_fields was included in incoming params
          if uf && uf.key?(:conditional_fields)
            begin
              Rails.logger.info("[discourse-authentication-validations] Incoming conditional_fields param class=#{uf[:conditional_fields].class} present=true")
            rescue
            end
          else
            Rails.logger.info("[discourse-authentication-validations] Incoming conditional_fields param present=false")
          end

          # If missing `conditional_fields`, and
          # custom validation is enabled for this field, treat that as an
          # explicit empty array (the admin removed all rules).
          # This is needed because empty arrays don't submit params from form.
          if uf && (!uf.key?(:conditional_fields) || uf[:conditional_fields].blank?)
            has_cv = uf.key?(:has_custom_validation) ? uf[:has_custom_validation] : nil
            if has_cv.present?
              # Normalize presence values like 'on'/'true'/'1' to truthy
              if has_cv == true || has_cv.to_s =~ /^(true|on|1)$/i
                uf[:conditional_fields] = []
              end
            end
          end

          return unless uf && uf[:conditional_fields]

          cf = uf[:conditional_fields]

          # Convert ActionController::Parameters to plain Hash so checks below work
          if cf.respond_to?(:to_unsafe_h)
            begin
              cf = cf.to_unsafe_h
            rescue
              # ignore conversion errors
            end
          end

          # If it's already an Array - nothing to do
          return if cf.is_a?(Array)

          # If numeric-keyed Hash-like -> convert to ordered Array
          if cf.is_a?(Hash)
            numeric_keys = cf.keys.select { |k| k.to_s =~ /\A\d+\z/ }
            if numeric_keys.any?
              arr = numeric_keys.sort_by { |k| k.to_i }.map { |k| cf[k] }
              uf[:conditional_fields] = arr
            end
          end
        rescue
          # swallow errors silently in normalization
        end
      end
    end

    ::Admin::UserFieldsController.prepend(AdminUserFieldsParamsPatch)
  rescue LoadError
    # If admin controller isn't available in this runtime, skip silently.
  end
end
