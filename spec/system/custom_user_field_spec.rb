# frozen_string_literal: true

RSpec.describe "Discourse Authentication Validation - Custom User Field", type: :system, js: true do
  SHOW_VALIDATION_VALUE_1 = "show_validation"
  SHOW_VALIDATION_VALUE_2 = "show_validation_2"

  before { SiteSetting.discourse_authentication_validations_enabled = true }

  fab!(:user_field_without_validation) do
    Fabricate(
      :user_field,
      name: "without_validation",
      field_type: "text",
      editable: true,
      required: false,
      has_custom_validation: false,
      show_values: [],
      target_classes: [],
    )
  end

  fab!(:user_field_with_validation_1) do
    Fabricate(
      :user_field,
      name: "with_validation_1",
      field_type: "text",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: [],
      target_classes: [],
    )
  end

  fab!(:user_field_with_validation_2) do
    Fabricate(
      :user_field,
      name: "with_validation_2",
      field_type: "text",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: [SHOW_VALIDATION_VALUE_1, SHOW_VALIDATION_VALUE_2],
      target_classes: [build_user_field_name_css_target(user_field_with_validation_1, prefix: "")],
    )
  end

  def build_user_field_name_css_target(user_field, prefix: ".")
    "#{prefix}user-field-#{user_field.name}"
  end

  shared_examples "show target user field" do
    before { visit("/signup") }

    it "shows the target user field" do
      expect(page).to have_css(target_class)
    end
  end

  shared_examples "hide target user field" do
    before { visit("/signup") }

    it "shows the target user field" do
      expect(page).not_to have_css(target_class)
    end
  end

  context "when signing up" do
    context "when completing the initial render of user fields" do
      context "when user field has no custom validation" do
        let(:target_class) { build_user_field_name_css_target(user_field_without_validation) }

        context "when rendering user field" do
          include_examples "show target user field"
        end
      end

      context "when user field has custom validation" do
        context "when user field is included in target_classes" do
          let(:target_class) { build_user_field_name_css_target(user_field_with_validation_1) }

          context "when rendering user field" do
            include_examples "hide target user field"
          end
        end

        context "when user field is not included in target_classes" do
          let(:target_class) { build_user_field_name_css_target(user_field_with_validation_2) }

          context "when rendering user field" do
            include_examples "show target user field"
          end
        end
      end
    end

    context "when changing the value of user field with a custom validation" do
      context "when user field is included in target_classes" do
        let(:target_class) { build_user_field_name_css_target(user_field_with_validation_1) }
        let(:parent_of_target_class) do
          build_user_field_name_css_target(user_field_with_validation_2)
        end

        context "when show_values are set on parent user field of target" do
          context "when the input matches a show_values value" do
            include_examples "show target user field" do
              before { page.find(parent_of_target_class).fill_in(with: SHOW_VALIDATION_VALUE_1) }
            end
          end

          context "when the input does not match a show_values value" do
            include_examples "hide target user field" do
              before { page.find(parent_of_target_class).fill_in(with: "not a show_values value") }
            end
          end
        end

        context "when show_values are not set on parent user field of target" do
          include_examples "hide target user field" do
            before { page.find(parent_of_target_class).fill_in(with: "foo bar") }
          end
        end
      end

      context "when user field is not included in target_classes" do
        let(:target_class) { build_user_field_name_css_target(user_field_with_validation_2) }

        context "when rendering user field" do
          include_examples "show target user field"
        end
      end
    end
  end
end
