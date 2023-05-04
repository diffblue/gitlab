import { createWrapper } from '@vue/test-utils';

import { initGitAbuseRateLimitSettingsForm } from 'ee/admin/application_settings/reporting/git_abuse_settings';
import { parseFormProps } from 'ee/admin/application_settings/reporting/git_abuse_settings/utils';
import SettingsForm from 'ee/admin/application_settings/reporting/git_abuse_settings/components/settings_form.vue';

jest.mock('ee/admin/application_settings/reporting/git_abuse_settings/utils', () => ({
  parseFormProps: jest.fn().mockReturnValue({
    maxNumberOfRepositoryDownloads: 10,
    maxNumberOfRepositoryDownloadsWithinTimePeriod: 300,
    gitRateLimitUsersAllowlist: ['user1', 'user2'],
    gitRateLimitUsersAlertlist: [1, 2],
    autoBanUserOnExcessiveProjectsDownload: true,
  }),
}));

describe('initGitAbuseRateLimitSettingsForm', () => {
  let wrapper;
  let el;

  const findSettingsForm = () => wrapper.findComponent(SettingsForm);

  const createAppRoot = () => {
    el = document.createElement('div');
    el.setAttribute('id', 'js-git-abuse-rate-limit-settings-form');
    el.dataset.maxNumberOfRepositoryDownloads = 10;
    el.dataset.maxNumberOfRepositoryDownloadsWithinTimePeriod = 300;
    el.dataset.gitRateLimitUsersAllowlist = ['user1', 'user2'];
    el.dataset.gitRateLimitUsersAlertlist = [1, 2];
    el.dataset.autoBanUserOnExcessiveProjectsDownload = true;
    document.body.appendChild(el);

    wrapper = createWrapper(initGitAbuseRateLimitSettingsForm());
  };

  afterEach(() => {
    el = null;
  });

  describe('when there is no app root', () => {
    it('returns false', () => {
      expect(initGitAbuseRateLimitSettingsForm()).toBe(false);
    });
  });

  describe('when there is an app root', () => {
    beforeEach(() => {
      createAppRoot();
    });

    it('parses the form props from the dataset', () => {
      initGitAbuseRateLimitSettingsForm();

      expect(parseFormProps).toHaveBeenCalledWith(el.dataset);
    });

    it('passes props to form component', () => {
      expect(findSettingsForm().props()).toMatchObject({
        maxDownloads: 10,
        timePeriod: 300,
        allowlist: ['user1', 'user2'],
        alertlist: [1, 2],
        autoBanUsers: true,
      });
    });
  });
});
