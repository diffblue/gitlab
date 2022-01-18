import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { convertToGraphQLIds } from '~/graphql_shared/utils';
import { TYPE_PROJECT } from '~/graphql_shared/constants';
import { formatDate } from '~/lib/utils/datetime_utility';
import { ISO_SHORT_FORMAT } from '~/vue_shared/constants';

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

export const parseViolationsQueryFilter = ({ createdBefore, createdAfter, projectIds }) => ({
  projectIds: projectIds ? convertProjectIdsToGraphQl(projectIds) : [],
  createdBefore: formatDate(createdBefore, ISO_SHORT_FORMAT),
  createdAfter: formatDate(createdAfter, ISO_SHORT_FORMAT),
});
