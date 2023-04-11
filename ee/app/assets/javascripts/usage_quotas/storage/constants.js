import { s__ } from '~/locale';

export const STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE = s__(
  'UsageQuota|Learn more about usage quotas.',
);

export const STORAGE_STATISTICS_NAMESPACE_STORAGE_USED = s__('UsageQuota|Namespace storage used');

export const STORAGE_STATISTICS_PURCHASED_STORAGE_USED = s__('UsageQuota|Purchased storage used');

export const STORAGE_STATISTICS_PURCHASED_STORAGE = s__('UsageQuota|Purchased storage');

export const BUY_STORAGE = s__('UsageQuota|Buy storage');

export const NONE_THRESHOLD = 'none';
export const INFO_THRESHOLD = 'info';
export const ALERT_THRESHOLD = 'alert';
export const ERROR_THRESHOLD = 'error';

export const STORAGE_USAGE_THRESHOLDS = {
  [NONE_THRESHOLD]: 0.0,
  [INFO_THRESHOLD]: 0.5,
  [ALERT_THRESHOLD]: 0.95,
  [ERROR_THRESHOLD]: 1.0,
};
