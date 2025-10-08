import EmberObject from "@ember/object";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export default {
  name: "user-field-validation",
  initialize() {
    withPluginApi((api) => {
      api.addCustomUserFieldValidationCallback((userField) => {
        if (
          userField.field.has_custom_validation &&
          userField.field.value_validation_regex &&
          userField.value
        ) {
          if (
            !new RegExp(userField.field.value_validation_regex).test(
              userField.value
            )
          ) {
            return EmberObject.create({
              failed: true,
              reason: i18n(
                "discourse_authentication_validations.value_validation_error_message",
                {
                  user_field_name: userField.field.name,
                }
              ),
              element: userField.field.element,
            });
          }
        }
      });
    });
  },
};
