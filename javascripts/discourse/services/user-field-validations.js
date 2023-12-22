import Service from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { TrackedObject } from "@ember-compat/tracked-built-ins";
import { action } from "@ember/object";
import { next } from "@ember/runloop";

export default class UserFieldValidations extends Service {
  @tracked _userFieldValidationsMap = new TrackedObject();
  @tracked totalCustomValidationFields = 0;
  currentCustomValidationFieldCount = 0;

  @action
  setValidation(field, value) {
    this._userFieldValidationsMap[field.id] = field;
    this._bumpTotalCustomValidationFields();

    if (
      this.currentCustomValidationFieldCount ===
      this.totalCustomValidationFields
    ) {
      next(() =>
        this.crossCheckValidations(this._userFieldValidationsMap, value)
      );
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

  @action
  crossCheckValidations(userFieldValidationsMap, value) {
    for (const userField of Object.values(userFieldValidationsMap)) {
      const { showValues, hideValues, targetClasses } = userField;

      const shouldShow = showValues?.includes?.(value) && targetClasses.length;
      const shouldHide =
        (hideValues?.includes?.(value) && targetClasses.length) ||
        (showValues.length && !showValues.includes(value));

      if (shouldShow || shouldHide) {
        this._updateTargets(targetClasses, shouldShow);
      }
    }
  }

  _updateTargets(targetClasses, shouldShow) {
    const targets = document.querySelectorAll(
      targetClasses.map((className) => `.${className}`).join(", ")
    );
    targets.forEach((element) => {
      element.style.display = shouldShow ? "block" : "none";
    });
  }
}
