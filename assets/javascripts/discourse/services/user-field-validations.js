import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { next } from "@ember/runloop";
import Service, { service } from "@ember/service";

export default class UserFieldValidations extends Service {
  @service site;

  @tracked totalCustomValidationFields = 0;
  @tracked userFields;
  currentCustomValidationFieldCount = 0;

  @action
  setValidation(userField, value) {
    this._bumpTotalCustomValidationFields();

    if (
      this.currentCustomValidationFieldCount ===
      this.totalCustomValidationFields
    ) {
      next(() => this.crossCheckValidations(userField, value));
    }
  }

  @action
  crossCheckValidations(userField, value) {
    let shouldShow = userField.show_values.includes(value);
    if (value === null && userField.show_values.includes("null")) {
      shouldShow = true;
    }
    this._updateTargets(userField.target_user_field_ids, shouldShow);
  }

  _updateTargets(userFieldIds, shouldShow) {
    userFieldIds.forEach((id) => {
      const userField = this.site.user_fields.find((field) => field.id === id);
      const className = `user-field-${userField.name
        .toLowerCase()
        .replace(/\s+/g, "-")}`;
      const userFieldElement = document.querySelector(`.${className}`);
      if (userFieldElement) {
        userFieldElement.style.display = shouldShow ? "" : "none";
      }
    });
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
