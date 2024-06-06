import EmberObject from "@ember/object";
import { withPluginApi } from "discourse/lib/plugin-api";
import I18n from "discourse-i18n";

export default {
  name: "user-field-validation",
  initialize() {
    withPluginApi("1.33.0", (api) => {
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
              reason: I18n.t(
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
