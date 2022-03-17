import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import PipelineSecurityDashboard from './components/pipeline/pipeline_security_dashboard.vue';
import apolloProvider from './graphql/provider';
import createRouter from './router';
import createDashboardStore from './store';
import { DASHBOARD_TYPES } from './store/constants';
import { LOADING_VULNERABILITIES_ERROR_CODES } from './store/modules/vulnerabilities/constants';

export default () => {
  const el = document.getElementById('js-security-report-app');

  if (!el) {
    return null;
  }

  const {
    dashboardDocumentation,
    emptyStateSvgPath,
    pipelineId,
    pipelineIid,
    projectId,
    sourceBranch,
    vulnerabilitiesEndpoint,
    emptyStateUnauthorizedSvgPath,
    emptyStateForbiddenSvgPath,
    commitPathTemplate,
    projectFullPath,
    pipelineJobsPath,
    canAdminVulnerability,
    securityReportHelpPageLink,
    falsePositiveDocUrl,
    canViewFalsePositive,
  } = el.dataset;

  const loadingErrorIllustrations = {
    [LOADING_VULNERABILITIES_ERROR_CODES.UNAUTHORIZED]: emptyStateUnauthorizedSvgPath,
    [LOADING_VULNERABILITIES_ERROR_CODES.FORBIDDEN]: emptyStateForbiddenSvgPath,
  };

  return new Vue({
    el,
    apolloProvider,
    router: createRouter(),
    store: createDashboardStore({
      dashboardType: DASHBOARD_TYPES.PIPELINE,
    }),
    provide: {
      dashboardType: DASHBOARD_TYPES.PIPELINE,
      projectId: parseInt(projectId, 10),
      commitPathTemplate,
      projectFullPath,
      // fullPath is needed even though projectFullPath is already provided because
      // vulnerability_list_graphql.vue expects the property name to be 'fullPath'
      fullPath: projectFullPath,
      dashboardDocumentation,
      emptyStateSvgPath,
      canAdminVulnerability: parseBoolean(canAdminVulnerability),
      pipeline: {
        id: parseInt(pipelineId, 10),
        iid: parseInt(pipelineIid, 10),
        jobsPath: pipelineJobsPath,
        sourceBranch,
      },
      securityReportHelpPageLink,
      vulnerabilitiesEndpoint,
      loadingErrorIllustrations,
      falsePositiveDocUrl,
      canViewFalsePositive: parseBoolean(canViewFalsePositive),
    },
    render(createElement) {
      return createElement(PipelineSecurityDashboard);
    },
  });
};
