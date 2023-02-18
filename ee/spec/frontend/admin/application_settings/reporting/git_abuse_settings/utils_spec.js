import { parseFormProps } from 'ee/admin/application_settings/reporting/git_abuse_settings/utils';

describe('Git abuse rate limit settings utils', () => {
  describe('parseFormProps', () => {
    const input = {
      maxNumberOfRepositoryDownloads: '10',
      maxNumberOfRepositoryDownloadsWithinTimePeriod: '300',
      gitRateLimitUsersAllowlist: '["user1", "user2"]',
      gitRateLimitUsersAlertlist: '[1, 2]',
      autoBanUserOnExcessiveProjectsDownload: 'false',
    };

    it('returns the expected result', () => {
      expect(parseFormProps(input)).toStrictEqual({
        maxNumberOfRepositoryDownloads: 10,
        maxNumberOfRepositoryDownloadsWithinTimePeriod: 300,
        gitRateLimitUsersAllowlist: ['user1', 'user2'],
        gitRateLimitUsersAlertlist: [1, 2],
        autoBanUserOnExcessiveProjectsDownload: false,
      });
    });
  });
});
