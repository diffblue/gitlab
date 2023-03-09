import { createWrapper } from '@vue/test-utils';

import { initSettingsForm } from 'ee/group_settings/reporting';
import SettingsFormContainer from 'ee/admin/application_settings/reporting/git_abuse_settings/components/settings_form_container.vue';

describe('initSettingsForm', () => {
  const GROUP_FULL_PATH = 'the-group';
  const MAX_DOWNLOADS = 10;
  const TIME_PERIOD = 300;
  const ALLOWLIST = ['user1', 'user2'];
  const ALERTLIST = [1, 2];
  const AUTO_BAN_USERS = true;

  let wrapper;
  let el;

  const createAppRoot = () => {
    el = document.createElement('div');
    el.setAttribute('id', 'js-unique-project-download-limit-settings-form');
    el.dataset.groupFullPath = GROUP_FULL_PATH;
    el.dataset.maxNumberOfRepositoryDownloads = MAX_DOWNLOADS;
    el.dataset.maxNumberOfRepositoryDownloadsWithinTimePeriod = TIME_PERIOD;
    el.dataset.gitRateLimitUsersAllowlist = JSON.stringify(ALLOWLIST);
    el.dataset.gitRateLimitUsersAlertlist = JSON.stringify(ALERTLIST);
    el.dataset.autoBanUserOnExcessiveProjectsDownload = AUTO_BAN_USERS;
    document.body.appendChild(el);

    wrapper = createWrapper(initSettingsForm());
  };

  it('returns false when there is no app root', () => {
    expect(initSettingsForm()).toBe(false);
  });

  describe('when there is an app root', () => {
    beforeEach(() => {
      createAppRoot();
    });

    afterEach(() => {
      el = null;
    });

    it('renders SettingsFormContainer with the correct props', () => {
      expect(wrapper.findComponent(SettingsFormContainer).props()).toMatchObject({
        groupFullPath: GROUP_FULL_PATH,
        maxDownloads: 10,
        timePeriod: 300,
        allowlist: ALLOWLIST,
        alertlist: ALERTLIST,
        autoBanUsers: AUTO_BAN_USERS,
      });
    });
  });
});
