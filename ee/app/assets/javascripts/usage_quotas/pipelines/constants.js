import { s__, __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const USAGE_BY_MONTH = s__('UsageQuota|CI minutes usage by month');
export const USAGE_BY_PROJECT = s__('UsageQuota|CI minutes usage by project');
export const X_AXIS_MONTH_LABEL = __('Month');
export const X_AXIS_PROJECT_LABEL = __('Projects');
export const Y_AXIS_SHARED_RUNNER_LABEL = __('Duration (min)');
export const Y_AXIS_PROJECT_LABEL = __('CI/CD minutes');
export const NO_CI_MINUTES_MSG = s__('UsageQuota|No CI minutes usage data available.');
export const CI_CD_MINUTES_USAGE = s__('UsageQuota|CI/CD minutes usage');
export const SHARED_RUNNER_USAGE = s__('UsageQuota|Shared runner duration');

export const X_AXIS_CATEGORY = 'category';
export const formatWithUtc = true;

export const SHARED_RUNNER_POPOVER_OPTIONS = {
  triggers: 'hover',
  placement: 'top',
  content: s__(
    'CICDAnalytics|Shared runner duration is the total runtime of all jobs that ran on shared runners',
  ),
  title: s__('CICDAnalytics|What is shared runner duration?'),
};

export const PROJECTS_TABLE_LABEL_PROJECT = __('Project');
export const PROJECTS_TABLE_LABEL_SHARED_RUNNERS = s__('UsageQuota|Shared runner duration');
export const PROJECTS_TABLE_LABEL_MINUTES = s__('UsageQuota|CI/CD minutes usage');
export const PROJECTS_TABLE_USAGE_SINCE = s__(
  'UsageQuota|The table below shows usage since %{usageSince}',
);
export const PROJECTS_TABLE_FIELDS = [
  {
    key: 'project',
    label: PROJECTS_TABLE_LABEL_PROJECT,
    sortable: true,
  },
  {
    key: 'shared_runners',
    label: PROJECTS_TABLE_LABEL_SHARED_RUNNERS,
    sortable: true,
  },
  {
    key: 'ci_minutes',
    label: PROJECTS_TABLE_LABEL_MINUTES,
    sortable: true,
  },
];

export const TITLE_USAGE_SINCE = s__('UsageQuota|CI/CD minutes usage since %{usageSince}');
export const TOTAL_USED_UNLIMITED = __('Unlimited');
export const MINUTES_USED = __('%{minutesUsed} minutes');
export const ADDITIONAL_MINUTES = __('Additional minutes');
export const PERCENTAGE_USED = __('%{percentageUsed}%% used');

export const ERROR_MESSAGE = s__(
  'UsageQuota|Something went wrong while fetching pipeline statistics',
);

export const PROJECTS_NO_SHARED_RUNNERS = s__(
  'UsageQuota|This namespace has no projects which used shared runners in the current period',
);
export const PROJECTS_TABLE_OMITS_MESSAGE = s__(
  'UsageQuota|This table omits projects that used 0 CI/CD minutes or 0 shared runners duration',
);
export const LABEL_BUY_ADDITIONAL_MINUTES = s__('UsageQuota|Buy additional minutes');
export const LABEL_CI_MINUTES_DISABLED = s__(
  'UsageQuota|%{linkStart}Shared runners%{linkEnd} are disabled, so there are no limits set on pipeline usage',
);
export const ADDITIONAL_MINUTES_HELP_LINK = helpPagePath('ci/pipelines/cicd_minutes', {
  anchor: 'purchase-additional-cicd-minutes-free-saas',
});
export const SHARED_RUNNERS_DOC_LINK = helpPagePath('ci/runners/index.md');
export const CI_MINUTES_HELP_LINK = helpPagePath('ci/pipelines/cicd_minutes');
export const CI_MINUTES_HELP_LINK_LABEL = __('Shared runners help link');
