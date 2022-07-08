import { parseBoolean } from '~/lib/utils/common_utils';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import findingsQuery from 'ee/security_dashboard/graphql/queries/pipeline_findings.query.graphql';
import { LOADING_VULNERABILITIES_ERROR_CODES } from 'ee/security_dashboard/store/modules/vulnerabilities/constants';

export const getPipelineReportOptions = (data) => {
  const {
    commitPathTemplate,
    projectFullPath,
    emptyStateSvgPath,
    vulnerabilitiesEndpoint,
    projectId,
    canAdminVulnerability,
    pipelineId,
    pipelineIid,
    pipelineJobsPath,
    sourceBranch,
    emptyStateUnauthorizedSvgPath,
    emptyStateForbiddenSvgPath,
    canViewFalsePositive,
  } = data;
  const loadingErrorIllustrations = {
    [LOADING_VULNERABILITIES_ERROR_CODES.UNAUTHORIZED]: emptyStateUnauthorizedSvgPath,
    [LOADING_VULNERABILITIES_ERROR_CODES.FORBIDDEN]: emptyStateForbiddenSvgPath,
  };
  return {
    commitPathTemplate,
    projectFullPath,
    emptyStateSvgPath,
    vulnerabilitiesEndpoint,
    dashboardType: DASHBOARD_TYPES.PIPELINE,
    projectId: Number(projectId),
    // fullPath is needed even though projectFullPath is already provided because
    // vulnerability_list_graphql.vue expects the property name to be 'fullPath'
    fullPath: projectFullPath,
    canAdminVulnerability: parseBoolean(canAdminVulnerability),
    pipeline: {
      id: Number(pipelineId),
      iid: Number(pipelineIid),
      jobsPath: pipelineJobsPath,
      sourceBranch,
    },
    loadingErrorIllustrations,
    canViewFalsePositive: parseBoolean(canViewFalsePositive),
    vulnerabilitiesQuery: findingsQuery,
  };
};
