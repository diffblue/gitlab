export const parseFormProps = ({
  maxNumberOfRepositoryDownloads,
  maxNumberOfRepositoryDownloadsWithinTimePeriod,
  gitRateLimitUsersAllowlist,
}) => ({
  maxNumberOfRepositoryDownloads: parseInt(maxNumberOfRepositoryDownloads, 10),
  maxNumberOfRepositoryDownloadsWithinTimePeriod: parseInt(
    maxNumberOfRepositoryDownloadsWithinTimePeriod,
    10,
  ),
  gitRateLimitUsersAllowlist: JSON.parse(gitRateLimitUsersAllowlist),
});
