# frozen_string_literal: true

RSpec.describe "Discourse Authentication Validation - Custom User Field - Dropdown Field", type: :system, js: true do
  SHOW_VALIDATION_VALUE_1 = "show_validation"
  SHOW_VALIDATION_VALUE_2 = "show_validation_2"
  NOT_A_SHOW_VALIDATION_VALUE = "not a show_values value"

  before { SiteSetting.discourse_authentication_validations_enabled = true }

  fab!(:user_field_without_validation) do
    Fabricate(
      :user_field,
      name: "without_validation",
      field_type: "dropdown",
      editable: true,
      required: false,
      has_custom_validation: false,
      show_values: [],
      target_user_field_ids: [],
    ) do
      user_field_options {[Fabricate(:user_field_option, value: NOT_A_SHOW_VALIDATION_VALUE)]} 
    end
  end

  fab!(:user_field_without_validation_2) do
    Fabricate(
      :user_field,
      name: "without_validation_2",
      field_type: "dropdown",
      editable: true,
      required: false,
      has_custom_validation: false,
      show_values: [],
      target_user_field_ids: [],
    ) do
      user_field_options {[Fabricate(:user_field_option, value: NOT_A_SHOW_VALIDATION_VALUE)]} 
    end
  end

  fab!(:user_field_with_validation_1) do
    Fabricate(
      :user_field,
      name: "with_validation_1",
      field_type: "dropdown",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: [],
      target_user_field_ids: [],
    ) do
      user_field_options {[Fabricate(:user_field_option, value: NOT_A_SHOW_VALIDATION_VALUE)]} 
    end
  end

  fab!(:user_field_with_validation_2) do
    Fabricate(
      :user_field,
      name: "with_validation_2",
      field_type: "dropdown",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: [SHOW_VALIDATION_VALUE_1, SHOW_VALIDATION_VALUE_2],
      target_user_field_ids: [user_field_with_validation_1.id],
    ) do
      user_field_options do
        [
          Fabricate(:user_field_option, value: NOT_A_SHOW_VALIDATION_VALUE),
          Fabricate(:user_field_option, value: SHOW_VALIDATION_VALUE_1),
        ]
      end
    end
  end

  fab!(:user_field_with_validation_3) do
    Fabricate(
      :user_field,
      name: "with_validation_3",
      field_type: "dropdown",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: [],
      target_user_field_ids: [user_field_without_validation_2.id],
    ) do
      user_field_options {[Fabricate(:user_field_option, value: NOT_A_SHOW_VALIDATION_VALUE)]}
    end
  end

  def build_user_field_css_target(user_field)
    ".user-field-#{user_field.name}"
  end

  context "when user field has no custom validation" do
    let(:target_class) { build_user_field_css_target(user_field_without_validation) }

    it "shows the target user field" do
      visit("/signup")
      expect(page).to have_css(target_class)
    end
  end

  context "when user field has custom validation" do
    context "when user field is included in target_user_field_ids" do
      let(:target_class) { build_user_field_css_target(user_field_with_validation_1) }

      it "hides the target user field" do
        visit("/signup")
        expect(page).not_to have_css(target_class)
      end
    end

    context "when user field is not included in target_user_field_ids" do
      let(:target_class) { build_user_field_css_target(user_field_with_validation_2) }

      it "shows the target user field" do
        visit("/signup")
        expect(page).to have_css(target_class)
      end
    end
  end

  context "when changing the value of user field with a custom validation and user field is included in target_user_field_ids" do
    context "when show_values are set on parent user field of target" do
      let(:target_class) { build_user_field_css_target(user_field_with_validation_1) }
      let(:parent_of_target_class) { build_user_field_css_target(user_field_with_validation_2) }

      context "when the input matches a show_values value" do
        it "shows the target user field" do
          visit("/signup")
          select_kit =
            PageObjects::Components::SelectKit.new("#{parent_of_target_class} .select-kit")
          select_kit.expand
          select_kit.select_row_by_value(SHOW_VALIDATION_VALUE_1)

          expect(page).to have_css(target_class)
        end
      end

      context "when the input does not match a show_values value" do
        it "hides the target user field" do
          visit("/signup")
          select_kit =
            PageObjects::Components::SelectKit.new("#{parent_of_target_class} .select-kit")
          select_kit.expand
          select_kit.select_row_by_value(NOT_A_SHOW_VALIDATION_VALUE)

          expect(page).not_to have_css(target_class)
        end
      end
    end

    context "when show_values are not set on parent user field of target" do
      let(:target_class) { build_user_field_css_target(user_field_without_validation_2) }
      let(:parent_of_target_class) { build_user_field_css_target(user_field_with_validation_3) }

      it "hides the target user field" do
        visit("/signup")
        select_kit =
          PageObjects::Components::SelectKit.new("#{parent_of_target_class} .select-kit")
        select_kit.expand
        select_kit.select_row_by_value(NOT_A_SHOW_VALIDATION_VALUE)

        expect(page).not_to have_css(target_class)
      end
    end
  end
end
