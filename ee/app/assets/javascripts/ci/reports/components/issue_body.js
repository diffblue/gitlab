import LicenseStatusIcon from 'ee/vue_shared/license_compliance/components/license_status_icon.vue';
import {
  components as componentsCE,
  componentNames as componentNamesCE,
  iconComponents as iconComponentsCE,
  iconComponentNames as iconComponentNamesCE,
} from '~/ci/reports/components/issue_body';

export const components = {
  ...componentsCE,
  PerformanceIssueBody: () =>
    import('ee/vue_merge_request_widget/components/performance_issue_body.vue'),
  LicenseIssueBody: () =>
    import('ee/vue_shared/license_compliance/components/license_issue_body.vue'),
  SecurityIssueBody: () =>
    import('ee/vue_shared/security_reports/components/security_issue_body.vue'),
  MetricsReportsIssueBody: () =>
    import('ee/vue_shared/metrics_reports/components/metrics_reports_issue_body.vue'),
  BlockingMergeRequestsBody: () =>
    import(
      'ee/vue_merge_request_widget/components/blocking_merge_requests/blocking_merge_request_body.vue'
    ),
};

export const componentNames = {
  ...componentNamesCE,
  PerformanceIssueBody: 'PerformanceIssueBody',
  LicenseIssueBody: 'LicenseIssueBody',
  SecurityIssueBody: 'SecurityIssueBody',
  MetricsReportsIssueBody: 'MetricsReportsIssueBody',
  BlockingMergeRequestsBody: 'BlockingMergeRequestsBody',
};

export const iconComponents = {
  ...iconComponentsCE,
  LicenseStatusIcon,
};

export const iconComponentNames = {
  ...iconComponentNamesCE,
  LicenseStatusIcon: LicenseStatusIcon.name,
};
