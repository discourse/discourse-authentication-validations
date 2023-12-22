import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { inject as service } from "@ember/service";
import setupUserFieldValidation from "../../helpers/setup-user-field-validation";

export default class Validations extends Component {
  @service userFieldValidations;

  constructor() {
    super(...arguments);

    this.userFieldValidations.totalCustomValidationFields =
      this.args.outletArgs.userFields.filterBy(
        "field.hasCustomValidation"
      ).length;
  }

  <template>
    {{#each @outletArgs.userFields as |field|}}
      {{#if field.field.has_custom_validation}}
        {{setupUserFieldValidation (hash field=field.field value=field.value)}}
      {{/if}}
    {{/each}}
  </template>
}
