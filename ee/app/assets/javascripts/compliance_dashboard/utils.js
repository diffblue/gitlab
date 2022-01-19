import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { convertToGraphQLIds } from '~/graphql_shared/utils';
import { TYPE_PROJECT } from '~/graphql_shared/constants';

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

export const convertProjectIdsToGraphQl = (projectIds) =>
  convertToGraphQLIds(
    TYPE_PROJECT,
    projectIds.filter((id) => Boolean(id)),
  );
