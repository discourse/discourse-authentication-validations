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
    // Determine which direct target ids are currently hidden for this userField/value
    let hiddenDirectTargets = [];

    const cfs = userField.conditional_fields;
    if (Array.isArray(cfs) && cfs.length >= 1) {
      // Build candidate set only from the conditional_fields rules themselves.
      // Do NOT mix in legacy userField.target_user_field_ids when conditional_fields are present.
      const candidateSet = new Set();
      cfs.forEach((rule) => {
        (rule.target_user_field_ids || []).forEach((v) => candidateSet.add(Number(v)));
      });

      Array.from(candidateSet).forEach((id) => {
        const should = this._shouldShowForTarget(userField, value, id);
        if (!should) {
          hiddenDirectTargets.push(id);
        }
      });
    } else {
      // Legacy behavior: if parent is not shown, all direct targets are hidden
      if (!this._shouldShow(userField, value)) {
        hiddenDirectTargets = (userField.target_user_field_ids || []).map((v) => Number(v));
      }
    }

    if (hiddenDirectTargets.length === 0) {
      return;
    }

    // For each hidden direct target, find its nested targets and clear/hide them
    const nestedUserFields = hiddenDirectTargets
      .flatMap((tid) => {
        const nestedField = this.site.user_fields.find((f) => f.id === tid);
        if (!nestedField) {
          return [];
        }
        return this.site.user_fields.filter((field) =>
          (nestedField.target_user_field_ids || []).map((v) => Number(v)).includes(field.id)
        );
      });

    // Clear and hide nested fields
    nestedUserFields.forEach((field) => this._clearUserField(field));
    this._updateTargets(nestedUserFields.map((field) => field.id), false);
  }

  @action
  crossCheckValidations(userField, value) {
    const cfs = userField.conditional_fields;

    // If conditional_fields exists and has rules, prefer those rules.
    if (Array.isArray(cfs) && cfs.length >= 1) {
      // build candidate set of all target ids referenced by this field or its rules
      // Build candidate set only from the conditional_fields rules themselves.
      // Do NOT mix in legacy userField.target_user_field_ids when conditional_fields are present.
      const candidateSet = new Set();
      cfs.forEach((rule) => {
        (rule.target_user_field_ids || []).forEach((v) => candidateSet.add(Number(v)));
      });

      const toShow = [];
      const toHide = [];

      const stringValue = value?.toString();
      const isNull = value === null;

      Array.from(candidateSet).forEach((id) => {
        let matched = false;

        for (const rule of cfs) {
          let sv = rule.show_values || rule.show_values === 0 ? rule.show_values : rule.show_value;

          // normalize show values to array of strings
          let showArr = [];
          if (Array.isArray(sv)) {
            showArr = sv.map((v) => (v === null ? "null" : v?.toString()));
          } else if (sv !== undefined && sv !== null) {
            showArr = [(sv === null ? "null" : sv.toString())];
          }

          const ruleMatchesValue = isNull ? showArr.includes("null") : showArr.includes(stringValue);
          if (!ruleMatchesValue) {
            continue;
          }

          const targetIds = (rule.target_user_field_ids || []).map((v) => Number(v));
          if (targetIds.includes(Number(id))) {
            matched = true;
            break;
          }
        }

        if (matched) {
          toShow.push(id);
        } else {
          toHide.push(id);
        }
      });

      // Update visibility for matched and unmatched targets
      if (toShow.length) {
        this._updateTargets(toShow, true);
      }
      if (toHide.length) {
        this._updateTargets(toHide, false);
      }
    } else {
      // Fallback to legacy behavior when no conditional_fields rules exist
      this._updateTargets(
        userField.target_user_field_ids,
        this._shouldShow(userField, value)
      );
    }
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

  // Determine whether a specific target id should be shown for the given
  // parent userField and value, taking conditional_fields into account if
  // present. Falls back to legacy behavior when conditional_fields absent.
  _shouldShowForTarget(userField, value, id) {
    const cfs = userField.conditional_fields;
    const stringValue = value?.toString();
    const isNull = value === null;

    if (Array.isArray(cfs) && cfs.length >= 1) {
      for (const rule of cfs) {
        const sv = rule.show_values || rule.show_value;

        let showArr = [];
        if (Array.isArray(sv)) {
          showArr = sv.map((v) => (v === null ? "null" : v?.toString()));
        } else if (sv !== undefined && sv !== null) {
          showArr = [(sv === null ? "null" : sv.toString())];
        }

        const ruleMatchesValue = isNull ? showArr.includes("null") : showArr.includes(stringValue);
        if (!ruleMatchesValue) {
          continue;
        }

        const targetIds = (rule.target_user_field_ids || []).map((v) => Number(v));
        if (targetIds.includes(Number(id))) {
          return true;
        }
      }

      return false;
    }

    // Legacy fallback: show if parent would be shown at all and id is a declared target
    if (this._shouldShow(userField, value)) {
      return (userField.target_user_field_ids || []).map((v) => Number(v)).includes(Number(id));
    }

    return false;
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
