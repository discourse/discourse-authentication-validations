import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { action } from "@ember/object";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";
import AdminFormRow from "admin/components/admin-form-row";
import ValueList from "admin/components/value-list";
import MultiSelect from "select-kit/components/multi-select";
import DButton from "discourse/components/d-button";

export default class CustomUserFields extends Component {
  @service site;

  // Compute the list of other user fields dynamically — site.user_fields may
  // be populated asynchronously, so a getter ensures the MultiSelect has the
  // latest content on first render.
  get userFieldsMinusCurrent() {
    const currentId = this.args?.outletArgs?.userField?.id;
    return (this.site.user_fields || []).filter((userField) => userField.id !== currentId);
  }
  @tracked rules = [];

  constructor() {
    super(...arguments);

    // Ensure the admin form includes our custom properties when saving user fields
    withPluginApi((api) => {
      [
        "has_custom_validation",
        "show_values",
        "target_user_field_ids",
        "value_validation_regex",
        "conditional_fields",
      ].forEach((property) => api.includeUserFieldPropertyOnSave(property));
    });

    // ensure we load rules after render when args are available (handles async loads)
    scheduleOnce("afterRender", this, this._loadRules);
  }

  _loadRules() {
    try {
      const raw = this.args?.outletArgs?.userField?.conditional_fields;
      if (raw) {
        // case: JSON string
        if (Array.isArray(raw)) {
          this.rules = raw;
        // case: object returned from server
        } else if (raw && typeof raw === "object") {
          // prefer { rules: [...] } shape
          if (Array.isArray(raw.rules)) {
            this.rules = raw.rules;
          } else {
            // convert numeric-keyed objects to array: {0: {...},1: {...}}
            const numericKeys = Object.keys(raw).filter((k) => String(Number(k)) === String(k));
            if (numericKeys.length > 0) {
              this.rules = numericKeys
                .sort((a, b) => Number(a) - Number(b))
                .map((k) => raw[k]);
            } else {
              this.rules = [];
            }
          }
        }
      }
    } catch (e) {
      this.rules = [];
    }

    // Normalize target ids to numbers so MultiSelect matches the content's ids
    if (this.rules && Array.isArray(this.rules)) {
      this.rules = this.rules.map((r) => {
        const targets = r && r.target_user_field_ids ? r.target_user_field_ids : [];
        return {
          ...r,
          target_user_field_ids: Array.isArray(targets) ? targets.map((v) => Number(v)) : [],
        };
      });
    }

    // Always ensure at least one editable rule is present so admin can fill it in
    if (!this.rules || this.rules.length === 0) {
      this.rules = [{ show_values: [], target_user_field_ids: [] }];
    }
  }

  @action
  addRule(field) {
    this.rules = [...this.rules, { show_values: [], target_user_field_ids: [] }];
    if (field && typeof field.set === "function") {
      // pass the actual object so the admin form can serialize it properly (JSONB)
      field.set(this.rules);
    }
  }

  @action
  removeRule(field, idx) {
    const r = [...this.rules];
    r.splice(idx, 1);
    this.rules = r;
    if (field && typeof field.set === "function") {
      field.set(this.rules);
    }
  }

  @action
  updateShowValues(field, idx, newValues) {
    const r = [...this.rules];
    r[idx] = { ...r[idx], show_values: newValues || [] };
    this.rules = r;
    if (field && typeof field.set === "function") {
      field.set(this.rules);
    }
  }

  // Return a closure that ValueList can call with (newValues).
  @action
  getShowValuesHandler(idx, field) {
    return (newValues) => this.updateShowValues(field, idx, newValues);
  }

  @action
  updateTargets(field, idx, newTargets) {
    const r = [...this.rules];
    r[idx] = { ...r[idx], target_user_field_ids: (newTargets || []).map((v) => Number(v)) };
    this.rules = r;
    if (field && typeof field.set === "function") {
      field.set(this.rules);
    }
  }

  // Return a closure that MultiSelect can call with (newTargets).
  @action
  getTargetsHandler(idx, field) {
    return (newTargets) => this.updateTargets(field, idx, newTargets);
  }

  <template>
    <AdminFormRow @wrapLabel="true" @type="checkbox">
      <Input
        @type="checkbox"
        @checked={{@outletArgs.userField.has_custom_validation}}
        class="has-custom-validation-checkbox"
      />
      <span>
        {{i18n "discourse_authentication_validations.has_custom_validation"}}
      </span>
    </AdminFormRow>

    {{#if @outletArgs.userField.has_custom_validation}}
      <@outletArgs.form.Field
        @name="value_validation_regex"
        @title={{i18n
          "discourse_authentication_validations.value_validation_regex.label"
        }}
        @format="large"
        as |field|
      >
        <field.Input />
      </@outletArgs.form.Field>

      <@outletArgs.form.Field
        @name="show_values"
        @title={{i18n "discourse_authentication_validations.show_values.label"}}
        @description={{i18n
          "discourse_authentication_validations.show_values.description"
        }}
        @format="large"
        as |field|
      >
        <div style="margin-bottom:8px;color:#d9534f;font-size:0.95em">
          Deprecated: `{{i18n "discourse_authentication_validations.show_values.label"}}` is the legacy way to control visibility. Prefer
          using `{{i18n "discourse_authentication_validations.conditional_fields.label"}}` to author repeatable, explicit rules that
          control which target fields are shown for specific parent values.
        </div>
        <field.Custom>
          <ValueList
            @values={{@outletArgs.userField.show_values}}
            @inputType="array"
            @onChange={{field.set}}
          />
        </field.Custom>
      </@outletArgs.form.Field>

      <@outletArgs.form.Field
        @name="target_user_field_ids"
        @title={{i18n
          "discourse_authentication_validations.target_user_field_ids.label"
        }}
        @format="large"
        as |field|
      >
        <div style="margin-bottom:8px;color:#d9534f;font-size:0.95em">
          Deprecated: `{{i18n
          "discourse_authentication_validations.target_user_field_ids.label"
        }}` is the legacy mapping for which
          fields to show. Use `{{i18n "discourse_authentication_validations.conditional_fields.label"}}` instead to associate target
          fields with specific parent values in repeatable rules.
        </div>
        <field.Custom>
          <MultiSelect
            @id={{field.id}}
            @onChange={{field.set}}
            @value={{field.value}}
            @content={{this.userFieldsMinusCurrent}}
            class="target-user-field-ids-input"
          />
        </field.Custom>
      </@outletArgs.form.Field>

      <@outletArgs.form.Field
        @name="conditional_fields"
        @title={{i18n "discourse_authentication_validations.conditional_fields.label"}}
        @description={{i18n "discourse_authentication_validations.conditional_fields.description"}}
        @format="large"
        as |field|
      >
        <field.Custom>
          <div class="conditional-rules">
            {{#each this.rules as |rule idx|}}
              <div class="conditional-rule" data-index={{idx}}>
                <div class="item-row">
                  <div class="rule-show-values">
                    <label class="control-label">{{i18n "discourse_authentication_validations.conditional_fields_show_values.label"}}</label>
                    <ValueList
                      @values={{rule.show_values}}
                      @inputType="array"
                      @onChange={{this.getShowValuesHandler idx field}}
                    />
                  </div>

                  <div class="rule-targets">
                    <label class="control-label">{{i18n "discourse_authentication_validations.conditional_fields_target_user_field_ids.label"}}</label>
                    <MultiSelect
                      @onChange={{this.getTargetsHandler idx field}}
                      @value={{rule.target_user_field_ids}}
                      @content={{this.userFieldsMinusCurrent}}
                      class="rule-targets-input"
                    />
                  </div>

                  <div class="rule-remove-button">
                    <DButton
                      @action={{this.removeRule field idx}}
                      class="btn-default btn-small btn-danger"
                    >
                      {{i18n "discourse_authentication_validations.remove_rule_button.label"}}
                    </DButton>
                  </div>
                </div>
              </div>
            {{/each}}

            <div>
              <DButton
                @action={{this.addRule field}}
                @icon="plus"
                class="btn-primary"
              >
                {{i18n "discourse_authentication_validations.add_rule_button.label"}}
              </DButton>
            </div>

            <div style="margin-top:8px">
              <label class="control-label">{{i18n "discourse_authentication_validations.rules_preview.label"}}</label>
              <pre style="background:#f7f7f7;padding:8px;white-space:pre-wrap">{{JSON.stringify this.rules}}</pre>
            </div>
          </div>
        </field.Custom>
      </@outletArgs.form.Field>
    {{/if}}
  </template>
}
