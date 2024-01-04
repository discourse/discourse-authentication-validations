import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const userFields = {
  user_fields: [
    {
      id: 1,
      name: "test_with_validation",
      description: "test_with_validation",
      field_type: "text",
      editable: true,
      position: 1,
      has_custom_validation: true,
      show_values: [],
      target_user_field_ids: [],
    },
    {
      id: 2,
      name: "test_without_validation",
      description: "test_without_validation",
      field_type: "text",
      editable: true,
      position: 2,
      has_custom_validation: false,
      show_values: [],
      target_user_field_ids: [],
    },
  ],
};

acceptance(
  "Discourse Authentication Validations - Custom User Fields",
  function (needs) {
    needs.user();
    needs.settings({
      discourse_authentication_validations_enabled: true,
    });
    needs.site(userFields);
    needs.pretender((server, helper) => {
      server.get("/admin/customize/user_fields", () =>
        helper.response(200, userFields)
      );
    });

    test("Shows `has_custom_validation` checkbox", async function (assert) {
      await visit("/admin/customize/user_fields");
      await click(".user-field button.edit");

      assert
        .dom(".user-field .has-custom-validation-checkbox")
        .exists("Checkbox for `has_custom_validation` exists");
    });

    test("Additional custom validation fields are hidden until `has_custom_validation` checkbox is active", async function (assert) {
      await visit("/admin/customize/user_fields");
      // select a user field with no custom validation
      await click(".user-field:last-of-type button.edit");

      assert
        .dom(".user-field .has-custom-validation-checkbox")
        .isNotChecked("Checkbox for `has_custom_validation` is unchecked");
      assert.dom(".user-field .show-values-input").doesNotExist();
      assert.dom(".user-field .target-classes-inpu").doesNotExist();
    });
  }
);
