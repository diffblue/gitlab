import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import findingsQuery from 'ee/security_dashboard/graphql/queries/pipeline_findings.query.graphql';
import PipelineSecurityDashboard from './components/pipeline/pipeline_security_dashboard.vue';
import apolloProvider from './graphql/provider';
import createRouter from './router';
import { DASHBOARD_TYPES } from './store/constants';
import { LOADING_VULNERABILITIES_ERROR_CODES } from './store/modules/vulnerabilities/constants';

// This can be removed when the migration to GraphQL is completed.
// Though, if we complete the pipeline tabs migration first, we will be removing this whole file.
Vue.use(Vuex);

export default () => {
  const el = document.getElementById('js-security-report-app');

  if (!el) {
    return null;
  }

  const {
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
    store: new Vuex.Store(),
    provide: {
      dashboardType: DASHBOARD_TYPES.PIPELINE,
      projectId: parseInt(projectId, 10),
      commitPathTemplate,
      projectFullPath,
      // fullPath is needed even though projectFullPath is already provided because
      // vulnerability_list_graphql.vue expects the property name to be 'fullPath'
      fullPath: projectFullPath,
      emptyStateSvgPath,
      canAdminVulnerability: parseBoolean(canAdminVulnerability),
      pipeline: {
        id: parseInt(pipelineId, 10),
        iid: parseInt(pipelineIid, 10),
        jobsPath: pipelineJobsPath,
        sourceBranch,
      },
      vulnerabilitiesEndpoint,
      loadingErrorIllustrations,
      canViewFalsePositive: parseBoolean(canViewFalsePositive),
      vulnerabilitiesQuery: findingsQuery,
    },
    render(createElement) {
      return createElement(PipelineSecurityDashboard);
    },
  });
};
