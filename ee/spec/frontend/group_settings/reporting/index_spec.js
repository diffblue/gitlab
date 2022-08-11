import { createWrapper } from '@vue/test-utils';

import { initSettingsForm } from 'ee/group_settings/reporting';
import SettingsFormContainer from 'ee/admin/application_settings/reporting/git_abuse_settings/components/settings_form_container.vue';

describe('initSettingsForm', () => {
  const GROUP_ID = 99;
  const MAX_DOWNLOADS = 10;
  const TIME_PERIOD = 300;
  const ALLOWLIST = ['user1', 'user2'];

  let wrapper;
  let el;

  const createAppRoot = () => {
    el = document.createElement('div');
    el.setAttribute('id', 'js-unique-project-download-limit-settings-form');
    el.dataset.groupId = GROUP_ID;
    el.dataset.maxNumberOfRepositoryDownloads = MAX_DOWNLOADS;
    el.dataset.maxNumberOfRepositoryDownloadsWithinTimePeriod = TIME_PERIOD;
    el.dataset.gitRateLimitUsersAllowlist = JSON.stringify(ALLOWLIST);
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
      wrapper.destroy();
      el = null;
    });

    it('renders SettingsFormContainer with the correct props', () => {
      expect(wrapper.findComponent(SettingsFormContainer).props()).toMatchObject({
        groupId: GROUP_ID,
        maxDownloads: 10,
        timePeriod: 300,
        allowlist: ALLOWLIST,
      });
    });
  });
});
