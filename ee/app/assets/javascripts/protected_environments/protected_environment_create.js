import $ from 'jquery';
import CreateItemDropdown from '~/create_item_dropdown';
import createFlash from '~/flash';
import AccessorUtilities from '~/lib/utils/accessor';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { initAccessDropdown } from '~/projects/settings/init_access_dropdown';
import { ACCESS_LEVELS } from './constants';

const PROTECTED_ENVIRONMENT_INPUT = 'input[name="protected_environment[name]"]';
const REQUIRED_APPROVAL_COUNT_INPUT =
  'select[name="protected_environment[required_approval_count]"]';

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
        accessLevelsData: gon.deploy_access_levels,
        accessLevel: ACCESS_LEVELS.DEPLOY,
      },
    );

    accessDropdown.$on('select', (selected) => {
      this.selected = selected;
      this.onSelect();
    });

    this.createItemDropdown = new CreateItemDropdown({
      $dropdown: this.$form.find('.js-protected-environment-select'),
      defaultToggleLabel: __('Protected Environment'),
      fieldName: 'protected_environment[name]',
      onSelect: this.onSelectCallback,
      getData: ProtectedEnvironmentCreate.getProtectedEnvironments,
      filterRemote: true,
    });
  }

  // Enable submit button after selecting an option on select
  onSelect() {
    const toggle = !(this.$form.find(PROTECTED_ENVIRONMENT_INPUT).val() && this.selected.length);

    this.$form.find('input[type="submit"]').attr('disabled', toggle);
  }

  static getProtectedEnvironments(term, callback) {
    axios
      .get(gon.search_unprotected_environments_url, { params: { query: term } })
      .then(({ data }) => {
        const environments = [].concat(data);
        const results = environments.map((environment) => ({
          id: environment,
          text: environment,
          title: environment,
        }));
        callback(results);
      })
      .catch(() => {
        createFlash({
          message: __('An error occurred while fetching environments.'),
        });
        callback([]);
      });
  }

  getFormData() {
    const formData = {
      authenticity_token: this.$form.find('input[name="authenticity_token"]').val(),
      protected_environment: {
        name: this.$form.find(PROTECTED_ENVIRONMENT_INPUT).val(),
        required_approval_count: this.$form.find(REQUIRED_APPROVAL_COUNT_INPUT).val(),
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
        createFlash({
          message: __('Failed to protect the environment'),
        }),
      );
  }
}
