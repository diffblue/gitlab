import { parseBoolean } from '~/lib/utils/common_utils';

export const parseFormProps = ({
  maxNumberOfRepositoryDownloads,
  maxNumberOfRepositoryDownloadsWithinTimePeriod,
  gitRateLimitUsersAllowlist,
  autoBanUserOnExcessiveProjectsDownload,
}) => ({
  maxNumberOfRepositoryDownloads: parseInt(maxNumberOfRepositoryDownloads, 10),
  maxNumberOfRepositoryDownloadsWithinTimePeriod: parseInt(
    maxNumberOfRepositoryDownloadsWithinTimePeriod,
    10,
  ),
  gitRateLimitUsersAllowlist: JSON.parse(gitRateLimitUsersAllowlist),
  autoBanUserOnExcessiveProjectsDownload: parseBoolean(autoBanUserOnExcessiveProjectsDownload),
});
