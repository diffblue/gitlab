import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_INFO } from '~/alert';
import Api from 'ee/api';
import SettingsForm from 'ee/admin/application_settings/reporting/git_abuse_settings/components/settings_form.vue';
import SettingsFormContainer from 'ee/admin/application_settings/reporting/git_abuse_settings/components/settings_form_container.vue';
import {
  SUCCESS_MESSAGE,
  SAVE_ERROR_MESSAGE,
} from 'ee/admin/application_settings/reporting/git_abuse_settings/constants';

jest.mock('ee/api.js');
jest.mock('~/alert');

describe('SettingsFormContainer', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(SettingsFormContainer, {
      propsData: {
        timePeriod: 1,
        allowlist: ['user1'],
        alertlist: [1],
        autoBanUsers: true,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders SettingsForm with the correct props', () => {
    expect(wrapper.findComponent(SettingsForm).exists()).toEqual(true);
    expect(wrapper.findComponent(SettingsForm).props()).toMatchObject({
      isLoading: false,
      maxDownloads: 0,
      timePeriod: 1,
      allowlist: ['user1'],
      alertlist: [1],
      autoBanUsers: true,
    });
  });

  describe('when SettingsForm emits a "submit" event', () => {
    const payload = {
      maxDownloads: 1,
      timePeriod: 2,
      allowlist: ['user2'],
      alertlist: [7],
      autoBanUsers: false,
    };

    it('calls Api.updateApplicationSettings with the correct payload', () => {
      wrapper.findComponent(SettingsForm).vm.$emit('submit', payload);

      expect(Api.updateApplicationSettings).toHaveBeenCalledTimes(1);
      expect(Api.updateApplicationSettings).toHaveBeenCalledWith({
        max_number_of_repository_downloads: 1,
        max_number_of_repository_downloads_within_time_period: 2,
        git_rate_limit_users_allowlist: ['user2'],
        git_rate_limit_users_alertlist: [7],
        auto_ban_user_on_excessive_projects_download: false,
      });
    });

    it('creates an alert with the correct message and type', async () => {
      wrapper.findComponent(SettingsForm).vm.$emit('submit', payload);

      await nextTick();

      expect(createAlert).toHaveBeenCalledWith({ message: SUCCESS_MESSAGE, variant: VARIANT_INFO });
    });

    describe('Api.updateApplicationSettings fails', () => {
      it('creates an alert with the correct message and type', async () => {
        Api.updateApplicationSettings.mockImplementation(() => Promise.reject());

        wrapper.findComponent(SettingsForm).vm.$emit('submit', payload);

        await nextTick();

        expect(createAlert).toHaveBeenCalledWith({
          message: SAVE_ERROR_MESSAGE,
          captureError: true,
        });
      });
    });
  });
});
