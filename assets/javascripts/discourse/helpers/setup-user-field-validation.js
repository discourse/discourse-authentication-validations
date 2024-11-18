import Helper from "@ember/component/helper";
import { service } from "@ember/service";

export default class SetupUserFieldValidation extends Helper {
  @service userFieldValidations;

  compute([object]) {
    this.userFieldValidations.setValidation(object.field, object.value);
  }
}
