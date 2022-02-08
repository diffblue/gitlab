import { s__ } from '~/locale';

export const PRESENTABLE_APPROVERS_LIMIT = 2;

export const COMPLIANCE_TAB_COOKIE_KEY = 'compliance_dashboard_tabs';

export const INPUT_DEBOUNCE = 500;

export const CUSTODY_REPORT_PARAMETER = 'commit_sha';

export const DRAWER_AVATAR_SIZE = 24;

export const DRAWER_MAXIMUM_AVATARS = 20;

export const GRAPHQL_PAGE_SIZE = 20;

export const COMPLIANCE_DRAWER_CONTAINER_CLASS = '.content-wrapper';

const VIOLATION_TYPE_APPROVED_BY_AUTHOR = 'approved_by_author';
const VIOLATION_TYPE_APPROVED_BY_COMMITTER = 'approved_by_committer';
const VIOLATION_TYPE_APPROVED_BY_INSUFFICIENT_USERS = 'approved_by_insufficient_users';

export const MERGE_REQUEST_VIOLATION_REASONS = {
  0: VIOLATION_TYPE_APPROVED_BY_AUTHOR,
  1: VIOLATION_TYPE_APPROVED_BY_COMMITTER,
  2: VIOLATION_TYPE_APPROVED_BY_INSUFFICIENT_USERS,
};

export const MERGE_REQUEST_VIOLATION_MESSAGES = {
  [VIOLATION_TYPE_APPROVED_BY_AUTHOR]: s__('ComplianceReport|Approved by author'),
  [VIOLATION_TYPE_APPROVED_BY_COMMITTER]: s__('ComplianceReport|Approved by committer'),
  [VIOLATION_TYPE_APPROVED_BY_INSUFFICIENT_USERS]: s__('ComplianceReport|Less than 2 approvers'),
};

export const MERGE_REQUEST_VIOLATION_SEVERITY_LEVELS = {
  1: 'high',
  2: 'medium',
  3: 'low',
  4: 'info',
};

export const DEFAULT_SORT = 'SEVERITY_DESC';
