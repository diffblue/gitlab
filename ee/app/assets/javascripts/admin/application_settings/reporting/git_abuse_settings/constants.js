import { s__, __, sprintf } from '~/locale';

export const MIN_NUM_REPOS = 0;
export const MAX_NUM_REPOS = 10000;

export const MIN_TIME_PERIOD = 0;
export const MAX_TIME_PERIOD = 10 * 24 * 60 * 60; // 10 days in seconds;

export const MAX_ALLOWED_USERS = 100;

export const MIN_ALERTED_USERS = 1;
export const MAX_ALERTED_USERS = 100;

export const NUM_REPOS_BLANK_ERROR = s__(
  "GitAbuse|Number of repositories can't be blank. Set to 0 for no limit.",
);
export const NUM_REPOS_NAN_ERROR = s__('GitAbuse|Number of repositories must be a number.');
export const NUM_REPOS_LIMIT_ERROR = sprintf(
  s__(`GitAbuse|Number of repositories should be between %{minNumRepos}-%{maxNumRepos}.`),
  {
    minNumRepos: MIN_NUM_REPOS,
    maxNumRepos: MAX_NUM_REPOS,
  },
);

export const TIME_PERIOD_BLANK_ERROR = s__(
  "GitAbuse|Reporting time period can't be blank. Set to 0 for no limit.",
);
export const TIME_PERIOD_NAN_ERROR = s__('GitAbuse|Reporting time period must be a number.');
export const TIME_PERIOD_LIMIT_ERROR = sprintf(
  s__(
    `GitAbuse|Reporting time period should be between %{minTimePeriod}-%{maxTimePeriod} seconds.`,
  ),
  {
    minTimePeriod: MIN_TIME_PERIOD,
    maxTimePeriod: MAX_TIME_PERIOD,
  },
);

export const ALLOWED_USERS_LIMIT_ERROR = sprintf(
  s__(`GitAbuse|You cannot specify more than %{maxAllowedUsers} excluded users.`),
  {
    maxAllowedUsers: MAX_ALLOWED_USERS,
  },
);

export const NUM_REPO_LABEL = s__('GitAbuse|Number of repositories');
export const NUM_REPO_DESCRIPTION = s__(
  "GitAbuse|The maximum number of unique repositories a user can download in the specified time period before they're banned.",
);
export const REPORTING_TIME_PERIOD_LABEL = s__('GitAbuse|Reporting time period (seconds)');

export const ALLOWED_USERS_LABEL = s__('GitAbuse|Excluded users');
export const ALLOWED_USERS_DESCRIPTION = s__(
  'GitAbuse|Users who are excluded from the Git abuse rate limit.',
);

export const ALERTED_USERS_LABEL = s__('GitAbuse|Send notifications to');
export const ALERTED_USERS_DESCRIPTION = s__(
  'GitAbuse|Users who are emailed when Git abuse rate limit is exceeded.',
);
export const ALERTED_USERS_LIMIT_ERROR = sprintf(
  s__(`GitAbuse|Select between %{minAlertedUsers} and %{maxAlertedUsers} users to notify.`),
  {
    minAlertedUsers: MIN_ALERTED_USERS,
    maxAlertedUsers: MAX_ALERTED_USERS,
  },
);

export const AUTO_BAN_TOGGLE_LABEL = s__(
  'GitAbuse|Automatically ban users from this %{scope} when they exceed the specified limits',
);

export const SEARCH_USERS = __('Search users');
export const SEARCH_TERM_TOO_SHORT = __('Enter at least three characters to search');
export const NO_RESULTS = __('No results');

export const SAVE_CHANGES = __('Save changes');
export const SUCCESS_MESSAGE = __('Application settings saved successfully.');

export const LOAD_ERROR_MESSAGE = __(
  'An error occurred while saving your settings. Try saving them again.',
);
export const SAVE_ERROR_MESSAGE = __(
  'An error occurred while retrieving your settings. Reload the page to try again.',
);
