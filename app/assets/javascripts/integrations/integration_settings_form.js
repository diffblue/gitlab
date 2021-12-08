import initForm from './edit';

export default class IntegrationSettingsForm {
  constructor(formSelector) {
    this.formSelector = formSelector;
    this.$form = document.querySelector(formSelector);

    this.vue = null;

    // Form Metadata
    this.testEndPoint = this.$form.dataset.testUrl;
  }

  init() {
    // Init Vue component
    this.vue = initForm(
      document.querySelector('.js-vue-integration-settings'),
      document.querySelector('.js-vue-default-integration-settings'),
      this.formSelector,
    );
  }
}
