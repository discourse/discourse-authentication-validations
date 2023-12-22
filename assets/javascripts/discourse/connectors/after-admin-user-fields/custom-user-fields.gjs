import Component from "@glimmer/component";
import { Input } from "@ember/component";
import { withPluginApi } from "discourse/lib/plugin-api";
import i18n from "discourse-common/helpers/i18n";
import AdminFormRow from "admin/components/admin-form-row";
import ValueList from "admin/components/value-list";

export default class CustomUserFields extends Component {
  constructor() {
    super(...arguments);
    withPluginApi("1.21.0", (api) => {
      api.includeUserFieldPropertiesOnSave([
        "has_custom_validation",
        "show_values",
        "target_classes",
      ]);
    });
  }

  <template>
    <AdminFormRow @wrapLabel="true" @type="checkbox">
      <Input
        @type="checkbox"
        @checked={{@outletArgs.buffered.has_custom_validation}}
      />
      <span>
        {{i18n "discourse_authentication_validations.has_custom_validation"}}
      </span>
    </AdminFormRow>

    {{#if @outletArgs.buffered.has_custom_validation}}
      <AdminFormRow
        @label="discourse_authentication_validations.show_values.label"
      >
        <ValueList
          @values={{@outletArgs.buffered.show_values}}
          @inputType="array"
        />
        <span>
          {{i18n
            "discourse_authentication_validations.show_values.description"
          }}
        </span>
      </AdminFormRow>

      <AdminFormRow
        @label="discourse_authentication_validations.target_classes.label"
      >
        <ValueList
          @values={{@outletArgs.buffered.target_classes}}
          @inputType="array"
        />
        <span>
          {{i18n
            "discourse_authentication_validations.target_classes.description"
          }}
        </span>
      </AdminFormRow>
    {{/if}}
  </template>
}
