import $ from 'jquery';
import { createAlert } from '~/alert';
import AccessorUtilities from '~/lib/utils/accessor';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { initAccessDropdown } from '~/groups/settings/init_access_dropdown';
import { ACCESS_LEVELS } from './constants';

const PROTECTED_ENVIRONMENT_INPUT = 'select[name="protected_environment[name]"]';

export default class ProtectedEnvironmentCreate {
  constructor() {
    this.$form = $('.js-new-protected-environment');
    this.isLocalStorageAvailable = AccessorUtilities.canUseLocalStorage();
    this.buildDropdowns();
    this.bindEvents();
    this.selected = [];
  }

  bindEvents() {
    this.$form.on('submit', this.onFormSubmit.bind(this));
  }

  buildDropdowns() {
    // Cache callback
    this.onSelectCallback = this.onSelect.bind(this);

    // Allowed to Deploy dropdown
    const accessDropdown = initAccessDropdown(
      document.querySelector('.js-allowed-to-deploy-dropdown'),
      {
        accessLevel: ACCESS_LEVELS.DEPLOY,
      },
    );

    accessDropdown.$on('select', (selected) => {
      this.selected = selected;
      this.onSelect();
    });
  }

  // Enable submit button after selecting an option on select
  onSelect() {
    const toggle = !(this.$form.find(PROTECTED_ENVIRONMENT_INPUT).val() && this.selected.length);

    this.$form.find('button[type="submit"]').attr('disabled', toggle);
  }

  getFormData() {
    const formData = {
      authenticity_token: this.$form.find('input[name="authenticity_token"]').val(),
      protected_environment: {
        name: this.$form.find(PROTECTED_ENVIRONMENT_INPUT).val(),
      },
    };
    formData.protected_environment[`${ACCESS_LEVELS.DEPLOY}_attributes`] = this.selected;

    return formData;
  }

  onFormSubmit(e) {
    e.preventDefault();

    axios[this.$form.attr('method')](this.$form.attr('action'), this.getFormData())
      .then(() => {
        window.location.hash = 'js-protected-environments-settings';
        window.location.reload();
      })
      .catch(() =>
        createAlert({
          message: __('Failed to protect the environment'),
        }),
      );
  }
}
