import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { next } from "@ember/runloop";
import Service, { service } from "@ember/service";

export default class UserFieldValidations extends Service {
  @service site;

  @tracked totalCustomValidationFields = 0;
  currentCustomValidationFieldCount = 0;

  constructor() {
    super(...arguments);

    this._initializeOriginallyRequired();
  }

  _initializeOriginallyRequired() {
    this.site?.user_fields?.forEach((field) => {
      if (field.has_custom_validation && field.originally_required === undefined) {
        field.originally_required = field.required;
      }
    });
  }

  @action
  setValidation(userField, value) {
    // Initialize originally_required for userField if not done yet
    if (userField.originally_required === undefined) {
      userField.originally_required = userField.required;
    }

    this._bumpTotalCustomValidationFields();

    if (
      this.currentCustomValidationFieldCount ===
      this.totalCustomValidationFields
    ) {
      next(() => {
        this.crossCheckValidations(userField, value);
        this.hideNestedCustomValidations(userField, value);
      });
    }
  }

  @action
  hideNestedCustomValidations(userField, value) {
    if (!this._shouldShow(userField, value)) {
      const nestedUserFields = this.site.user_fields
        .filter((field) => userField.target_user_field_ids.includes(field.id))
        .flatMap((nestedField) =>
          this.site.user_fields.filter((field) =>
            nestedField.target_user_field_ids.includes(field.id)
          )
        );

      // Clear and hide nested fields
      nestedUserFields.forEach((field) => this._clearUserField(field));
      this._updateTargets(
        nestedUserFields.map((field) => field.id),
        false
      );
    }
  }

  @action
  crossCheckValidations(userField, value) {
    this._updateTargets(
      userField.target_user_field_ids,
      this._shouldShow(userField, value)
    );
  }

  _updateTargets(userFieldIds, shouldShow) {
    userFieldIds.forEach((id) => {
      const userField = this.site.user_fields.find((field) => field.id === id);
      const className = `user-field-${userField.name
        .toLowerCase()
        .replace(/\s+/g, "-")}`;
      const userFieldElement = document.querySelector(`.${className}`);

      // Save original required value on first call
      if (userField.originally_required === undefined) {
        userField.originally_required = userField.required;
      }

      if (userFieldElement && !shouldShow) {
        // Clear and hide nested fields
        userFieldElement.style.display = "none";
        this._clearUserField(userField);

        // Remove required for hidden field
        userField.required = false;
      } else {
        userFieldElement.style.display = "";

        //Restore original required for visible field
        if (userField.originally_required !== undefined) {
          userField.required = userField.originally_required;
        }
      }
    });
  }

  _shouldShow(userField, value) {
    let stringValue = value?.toString(); // Account for checkbox boolean values and `null`
    let shouldShow = userField.show_values.includes(stringValue);
    if (value === null && userField.show_values.includes("null")) {
      shouldShow = true;
    }
    return shouldShow;
  }

  _clearUserField(userField) {
    switch (userField.field_type) {
      case "confirm":
        userField.element.checked = false;
        break;
      case "dropdown":
        userField.element.selectedIndex = 0;
        break;
      default:
        userField.element.value = "";
        break;
    }
  }

  _bumpTotalCustomValidationFields() {
    if (
      this.totalCustomValidationFields !==
      this.currentCustomValidationFieldCount
    ) {
      this.currentCustomValidationFieldCount += 1;
    }
  }
}
