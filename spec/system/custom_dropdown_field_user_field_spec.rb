# frozen_string_literal: true

RSpec.describe "Discourse Authentication Validation - Custom User Field - Dropdown Field",
               type: :system do
  before { SiteSetting.discourse_authentication_validations_enabled = true }

  let(:custom_validation_page) { PageObjects::Pages::CustomValidation.new }

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
    ) { user_field_options { [Fabricate(:user_field_option, value: "not a show_values value")] } }
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
    ) { user_field_options { [Fabricate(:user_field_option, value: "not a show_values value")] } }
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
    ) { user_field_options { [Fabricate(:user_field_option, value: "not a show_values value")] } }
  end

  fab!(:user_field_with_validation_2) do
    Fabricate(
      :user_field,
      name: "with_validation_2",
      field_type: "dropdown",
      editable: true,
      required: false,
      has_custom_validation: true,
      show_values: ["show_validation"],
      target_user_field_ids: [user_field_with_validation_1.id],
    ) do
      user_field_options do
        [
          Fabricate(:user_field_option, value: "not a show_values value"),
          Fabricate(:user_field_option, value: "show_validation"),
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
      show_values: ["null"],
      target_user_field_ids: [user_field_without_validation_2.id],
    ) { user_field_options { [Fabricate(:user_field_option, value: "not a show_values value")] } }
  end

  it "shows the target user field when user field has no custom validation" do
    visit("/signup")
    expect(page).to have_css(custom_validation_page.target_class(user_field_without_validation))
  end

  context "when user field has custom validation" do
    before { visit("/signup") }

    it "hides the target user field when user field is included in target_user_field_ids" do
      expect(page).to have_no_css(custom_validation_page.target_class(user_field_with_validation_1))
    end

    it "shows the target user field when user field is not included in target_user_field_ids" do
      expect(page).to have_css(custom_validation_page.target_class(user_field_with_validation_2))
    end
  end

  context "when changing the value of user field with a custom validation and user field is included in target_user_field_ids" do
    context "when show_values are set on parent user field of target" do
      before { visit("/signup") }

      it "shows the target user field when the input matches a show_values value" do
        custom_validation_page.select_show_validation_value(
          custom_validation_page.target_class(user_field_with_validation_2),
        )
        expect(page).to have_css(custom_validation_page.target_class(user_field_with_validation_1))
      end

      it "hides the target user field when the input does not match a show_values value" do
        custom_validation_page.select_not_show_validation_value(
          custom_validation_page.target_class(user_field_with_validation_2),
        )
        expect(page).to have_no_css(
          custom_validation_page.target_class(user_field_with_validation_1),
        )
      end
    end

    context "when show_values includes `null` on the parent user field of target" do
      before { visit("/signup") }

      it "shows the target user field" do
        expect(page).to have_css(
          custom_validation_page.target_class(user_field_without_validation_2),
        )
      end

      it "toggles the display of the target after the value has changed" do
        custom_validation_page.select_not_show_validation_value(
          custom_validation_page.target_class(user_field_with_validation_3),
        )
        expect(page).to have_no_css(
          custom_validation_page.target_class(user_field_without_validation_2),
        )
      end
    end

    context "when show_values are not set on parent user field of target" do
      before { user_field_with_validation_2.show_values = [] }

      it "hides the target user field when show_values are not set on parent user field of target" do
        visit("/signup")
        custom_validation_page.select_not_show_validation_value(
          custom_validation_page.target_class(user_field_with_validation_2),
        )
        expect(page).to have_no_css(
          custom_validation_page.target_class(user_field_with_validation_1),
        )
      end
    end
  end
end
