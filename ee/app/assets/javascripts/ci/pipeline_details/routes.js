import LicenseReportApp from 'ee/vue_shared/license_compliance/mr_widget_license_report.vue';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import {
  codeQualityTabName,
  licensesTabName,
  securityTabName,
} from '~/ci/pipeline_details/constants';
import { routes as ceRoutes } from '~/ci/pipeline_details/routes';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline/pipeline_security_dashboard.vue';

export const routes = [
  ...ceRoutes,
  { name: securityTabName, path: '/security', component: PipelineSecurityDashboard },
  { name: licensesTabName, path: '/licenses', component: LicenseReportApp },
  { name: codeQualityTabName, path: '/codequality_report', component: CodequalityReportApp },
];
