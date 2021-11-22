import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const mapDashboardToDrawerData = (mergeRequest) => ({
  id: mergeRequest.id,
  mergeRequest: {
    ...convertObjectPropsToCamelCase(mergeRequest, { deep: true }),
    webUrl: mergeRequest.path,
  },
  project: {
    ...convertObjectPropsToCamelCase(mergeRequest.project, { deep: true }),
    complianceFramework: convertObjectPropsToCamelCase(
      mergeRequest.compliance_management_framework,
    ),
  },
});
