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
    for (const property in userFieldValidationsMap) {
      const userField = userFieldValidationsMap[property];

      // show values
      if (
        userField.showValues.length &&
        userField.targetClasses.length &&
        userField.showValues.includes(value)
      ) {
        const targets = document.querySelectorAll(
          userField.targetClasses.map((className) => `.${className}`).join(", ")
        );
        targets.forEach((element) => (element.style.display = "block"));
      }

      // hide values
      if (
        userField.hideValues.length &&
        userField.targetClasses.length &&
        userField.hideValues.includes(value)
      ) {
        const targets = document.querySelectorAll(
          userField.targetClasses.map((className) => `.${className}`).join(", ")
        );
        targets.forEach((element) => (element.style.display = "none"));
      } else if (
        userField.showValues.length &&
        !userField.showValues.includes(value)
      ) {
        const targets = document.querySelectorAll(
          userField.targetClasses.map((className) => `.${className}`).join(", ")
        );
        targets.forEach((element) => (element.style.display = "none"));
      }
    }
  }
}

// {id: 1, showValues: ["show", "foo"], hideValues: [""], targetClasses: ["field-class-1", "field-class-2"]}
// {id: 2, showValues: [""], hideValues: [""], targetClasses: [""]}
// {id: 2, showValues: [""], hideValues: [""], targetClasses: [""]}
