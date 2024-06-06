import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { inject as service } from "@ember/service";
import withEventValue from "discourse/helpers/with-event-value";
import { withPluginApi } from "discourse/lib/plugin-api";
import i18n from "discourse-common/helpers/i18n";
import AdminFormRow from "admin/components/admin-form-row";
import ValueList from "admin/components/value-list";
import MultiSelect from "select-kit/components/multi-select";

export default class CustomUserFields extends Component {
  @service site;

  @tracked userFieldsMinusCurrent = this.site.user_fields.filter(
    (userField) => userField.id !== this.args.outletArgs.buffered.content.id
  );

  constructor() {
    super(...arguments);
    withPluginApi("1.21.0", (api) => {
      [
        "has_custom_validation",
        "show_values",
        "target_user_field_ids",
        "value_validation_regex",
      ].forEach((property) => api.includeUserFieldPropertyOnSave(property));
    });
  }

  <template>
    <AdminFormRow @wrapLabel="true" @type="checkbox">
      <Input
        @type="checkbox"
        @checked={{@outletArgs.buffered.has_custom_validation}}
        class="has-custom-validation-checkbox"
      />
      <span>
        {{i18n "discourse_authentication_validations.has_custom_validation"}}
      </span>
    </AdminFormRow>

    {{#if @outletArgs.buffered.has_custom_validation}}
      <AdminFormRow
        @label="discourse_authentication_validations.value_validation_regex.label"
      >
        <input
          {{on
            "input"
            (withEventValue
              (fn (mut @outletArgs.buffered.value_validation_regex))
            )
          }}
          value={{@outletArgs.buffered.value_validation_regex}}
          type="text"
          class="value-validation-regex-input"
        />
        <br />
        <span>
          {{i18n
            "discourse_authentication_validations.value_validation_regex.description"
          }}
        </span>
      </AdminFormRow>

      <AdminFormRow
        @label="discourse_authentication_validations.show_values.label"
      >
        <ValueList
          @values={{@outletArgs.buffered.show_values}}
          @inputType="array"
          class="show-values-input"
        />
        <span>
          {{i18n
            "discourse_authentication_validations.show_values.description"
          }}
        </span>
      </AdminFormRow>

      <AdminFormRow
        @label="discourse_authentication_validations.target_user_field_ids.label"
      >
        <MultiSelect
          @content={{this.userFieldsMinusCurrent}}
          @valueProperty="id"
          @value={{@outletArgs.buffered.target_user_field_ids}}
          class="target-user-field-ids-input"
        />
        <br />
        <span>
          {{i18n
            "discourse_authentication_validations.target_user_field_ids.description"
          }}
        </span>
      </AdminFormRow>
    {{/if}}
  </template>
}
