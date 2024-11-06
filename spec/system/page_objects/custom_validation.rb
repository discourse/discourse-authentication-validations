# frozen_string_literal: true

module PageObjects
  module Pages
    class CustomValidation < PageObjects::Pages::Base
      def select_not_show_validation_value(selector)
        select_kit = PageObjects::Components::SelectKit.new("#{selector} .select-kit")
        select_kit.expand
        select_kit.select_row_by_value(self.not_a_show_value_validation_value)
      end

      def select_show_validation_value(selector)
        select_kit = PageObjects::Components::SelectKit.new("#{selector} .select-kit")
        select_kit.expand
        select_kit.select_row_by_value(self.show_value_validation_value)
      end

      def click_confirmation(selector)
        find("#{selector}.confirm input").click
      end

      def build_user_field_css_target(user_field)
        ".user-field-#{user_field.name}"
      end

      def target_class(user_field)
        build_user_field_css_target(user_field)
      end

      def show_value_validation_value
        "show_validation"
      end

      def not_a_show_value_validation_value
        "not a show_values value"
      end
    end
  end
end
