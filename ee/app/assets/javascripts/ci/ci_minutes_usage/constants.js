import { __, s__ } from '~/locale';

// i18n
export const USAGE_BY_MONTH = s__('UsageQuota|CI minutes usage by month');
export const USAGE_BY_PROJECT = s__('UsageQuota|CI minutes usage by project');
export const X_AXIS_MONTH_LABEL = __('Month');
export const X_AXIS_PROJECT_LABEL = __('Projects');
export const Y_AXIS_SHARED_RUNNER_LABEL = __('Duration (min)');
export const Y_AXIS_PROJECT_LABEL = __('CI/CD minutes');
export const NO_CI_MINUTES_MSG = s__('UsageQuota|No CI minutes usage data available.');
export const USAGE_BY_MONTH_HEADER = s__('UsageQuota|Usage by month');
export const USAGE_BY_PROJECT_HEADER = s__('UsageQuota|Usage by project');
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
