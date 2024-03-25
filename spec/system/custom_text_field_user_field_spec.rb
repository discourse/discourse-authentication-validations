# frozen_string_literal: true

RSpec.describe "Discourse Authentication Validation - Custom User Field - Text Field",
               type: :system,
               js: true do
  SHOW_VALIDATION_VALUE ||= "show_validation"

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
      target_user_field_ids: [],
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
      target_user_field_ids: [],
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
      show_values: [SHOW_VALIDATION_VALUE],
      target_user_field_ids: [user_field_with_validation_1.id],
    )
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
    let(:target_class) { build_user_field_css_target(user_field_with_validation_1) }
    let(:parent_of_target_class) { build_user_field_css_target(user_field_with_validation_2) }

    context "when show_values are set on parent user field of target" do
      context "when the input matches a show_values value" do
        it "shows the target user field" do
          visit("/signup")
          page.find(parent_of_target_class).fill_in(with: SHOW_VALIDATION_VALUE)
          expect(page).to have_css(target_class)
        end
      end

      context "when the input does not match a show_values value" do
        it "hides the target user field" do
          visit("/signup")
          page.find(parent_of_target_class).fill_in(with: "not a show_values value")
          expect(page).not_to have_css(target_class)
        end
      end
    end

    context "when show_values are not set on parent user field of target" do
      it "hides the target user field" do
        visit("/signup")
        page.find(parent_of_target_class).fill_in(with: "foo bar")
        expect(page).not_to have_css(target_class)
      end
    end
  end
end
