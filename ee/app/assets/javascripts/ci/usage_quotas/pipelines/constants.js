import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const PROJECTS_TABLE_LABEL_PROJECT = __('Project');
export const PROJECTS_TABLE_LABEL_MINUTES = __('Minutes');
export const PROJECTS_TABLE_FIELDS = [
  {
    key: 'project',
    label: PROJECTS_TABLE_LABEL_PROJECT,
    sortable: true,
  },
  {
    key: 'ci_minutes',
    label: PROJECTS_TABLE_LABEL_MINUTES,
    sortable: true,
  },
];

export const TITLE_USAGE_SINCE = s__('UsageQuota|CI/CD minutes usage since %{usageSince}');
export const TITLE_CURRENT_PERIOD = s__('UsageQuota|Current period usage');
export const TOTAL_USED_UNLIMITED = __('Unlimited');
export const MINUTES_USED = __('%{minutesUsed} minutes');
export const ADDITIONAL_MINUTES = __('Additional minutes');
export const PERCENTAGE_USED = __('%{percentageUsed}%% used');

export const ERROR_MESSAGE = s__(
  'UsageQuota|Something went wrong while fetching pipeline statistics',
);

export const LABEL_BUY_ADDITIONAL_MINUTES = s__('UsageQuota|Buy additional minutes');
export const LABEL_CI_MINUTES_DISABLED = s__(
  'UsageQuota|%{linkStart}Shared runners%{linkEnd} are disabled, so there are no limits set on pipeline usage',
);
export const LABEL_NO_PROJECTS = s__(
  'UsageQuota|This namespace has no projects which use shared runners',
);
export const USAGE_QUOTAS_HELP_LINK = helpPagePath('user/usage_quotas');
export const ADDITIONAL_MINUTES_HELP_LINK = helpPagePath('ci/pipelines/cicd_minutes', {
  anchor: 'purchase-additional-cicd-minutes-free-saas',
});
export const CI_MINUTES_HELP_LINK = helpPagePath('ci/pipelines/cicd_minutes');
export const CI_MINUTES_HELP_LINK_LABEL = __('Shared runners help link');
