import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { getIdFromGraphQLId, convertNodeIdsFromGraphQLIds } from '~/graphql_shared/utils';

export const mapViolations = (nodes = []) => {
  return nodes.map((node) => ({
    ...node,
    mergeRequest: {
      ...node.mergeRequest,
      committers: convertNodeIdsFromGraphQLIds(node.mergeRequest.committers?.nodes || []),
      approvedByUsers: convertNodeIdsFromGraphQLIds(node.mergeRequest.approvedBy?.nodes || []),
      participants: convertNodeIdsFromGraphQLIds(node.mergeRequest.participants?.nodes || []),
      reference: node.mergeRequest.ref,
      mergedBy: {
        ...convertObjectPropsToSnakeCase(node.mergeRequest.mergeUser),
        id: getIdFromGraphQLId(node.mergeRequest.mergeUser?.id),
      },
      project: {
        ...node.mergeRequest.project,
        complianceFramework: node.mergeRequest.project?.complianceFrameworks?.nodes[0] || null,
      },
    },
    violatingUser: {
      ...node.violatingUser,
      id: getIdFromGraphQLId(node.violatingUser.id),
    },
  }));
};
