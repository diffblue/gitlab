import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_INFO } from '~/alert';
import { updateGroupSettings } from 'ee/api/groups_api';
import SettingsForm from 'ee/admin/application_settings/reporting/git_abuse_settings/components/settings_form.vue';
import SettingsFormContainer from 'ee/group_settings/reporting/components/settings_form_container.vue';
import {
  SUCCESS_MESSAGE,
  SAVE_ERROR_MESSAGE,
} from 'ee/admin/application_settings/reporting/git_abuse_settings/constants';

jest.mock('ee/api/groups_api.js');
jest.mock('~/alert');

describe('SettingsFormContainer', () => {
  let wrapper;

  const GROUP_FULL_PATH = 'the-group';
  const MAX_DOWNLOADS = 10;
  const TIME_PERIOD = 300;
  const ALLOWLIST = ['user1', 'user2'];
  const ALERTLIST = [1, 2];
  const AUTO_BAN_USERS = true;

  const NEW_MAX_DOWNLOADS = 100;
  const NEW_TIME_PERIOD = 150;
  const NEW_ALLOWLIST = ['user3'];
  const NEW_ALERTLIST = [7];
  const NEW_AUTO_BAN_USERS = false;

  const createComponent = () => {
    wrapper = shallowMountExtended(SettingsFormContainer, {
      propsData: {
        groupFullPath: GROUP_FULL_PATH,
        maxDownloads: MAX_DOWNLOADS,
        timePeriod: TIME_PERIOD,
        allowlist: ALLOWLIST,
        alertlist: ALERTLIST,
        autoBanUsers: AUTO_BAN_USERS,
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
      maxDownloads: MAX_DOWNLOADS,
      timePeriod: TIME_PERIOD,
      allowlist: ALLOWLIST,
      alertlist: ALERTLIST,
      autoBanUsers: AUTO_BAN_USERS,
    });
  });

  describe('when SettingsForm emits a "submit" event', () => {
    const payload = {
      maxDownloads: NEW_MAX_DOWNLOADS,
      timePeriod: NEW_TIME_PERIOD,
      allowlist: NEW_ALLOWLIST,
      alertlist: NEW_ALERTLIST,
      autoBanUsers: NEW_AUTO_BAN_USERS,
    };

    it('calls updateGroupSettings with the correct payload', () => {
      wrapper.findComponent(SettingsForm).vm.$emit('submit', payload);

      expect(updateGroupSettings).toHaveBeenCalledTimes(1);
      expect(updateGroupSettings).toHaveBeenCalledWith(GROUP_FULL_PATH, {
        unique_project_download_limit: NEW_MAX_DOWNLOADS,
        unique_project_download_limit_interval_in_seconds: NEW_TIME_PERIOD,
        unique_project_download_limit_allowlist: NEW_ALLOWLIST,
        unique_project_download_limit_alertlist: NEW_ALERTLIST,
        auto_ban_user_on_excessive_projects_download: NEW_AUTO_BAN_USERS,
      });
    });

    it('creates an alert with the correct message and type', async () => {
      wrapper.findComponent(SettingsForm).vm.$emit('submit', payload);

      await nextTick();

      expect(createAlert).toHaveBeenCalledWith({ message: SUCCESS_MESSAGE, variant: VARIANT_INFO });
    });

    describe('updateGroupSettings fails', () => {
      it('creates an alert with the correct message and type', async () => {
        updateGroupSettings.mockImplementation(() => Promise.reject());

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
