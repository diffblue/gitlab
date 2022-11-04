import LicenseReportApp from 'ee/vue_shared/license_compliance/mr_widget_license_report.vue';
import CodequalityReportAppWrapper from 'ee/pipelines/components/codequality_report_app_wrapper.vue';
import { codeQualityTabName, licensesTabName, securityTabName } from '~/pipelines/constants';
import { routes as ceRoutes } from '~/pipelines/routes';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline/pipeline_security_dashboard.vue';

export const routes = [
  ...ceRoutes,
  { name: securityTabName, path: '/security', component: PipelineSecurityDashboard },
  { name: licensesTabName, path: '/licenses', component: LicenseReportApp },
  { name: codeQualityTabName, path: '/codequality_report', component: CodequalityReportAppWrapper },
];
