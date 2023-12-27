import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { next } from "@ember/runloop";
import Service from "@ember/service";

export default class UserFieldValidations extends Service {
  @tracked totalCustomValidationFields = 0;
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
    const shouldShow = userField.show_values?.includes?.(value);
    this._updateTargets(userField.target_classes, shouldShow);
  }

  _updateTargets(targetClasses, shouldShow) {
    targetClasses.forEach((className) => {
      const userField = document.querySelector(`.${className}`);
      if (userField) {
        userField.style.display = shouldShow ? "block" : "none";
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
