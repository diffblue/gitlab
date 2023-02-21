import { convertNodeIdsFromGraphQLIds, getIdFromGraphQLId } from '~/graphql_shared/utils';

export const mapViolations = (nodes = []) => {
  return nodes.map((node) => ({
    ...node,
    mergeRequest: {
      ...node.mergeRequest,
      committers: convertNodeIdsFromGraphQLIds(node.mergeRequest.committers?.nodes || []),
      approvedByUsers: convertNodeIdsFromGraphQLIds(node.mergeRequest.approvedBy?.nodes || []),
      participants: convertNodeIdsFromGraphQLIds(node.mergeRequest.participants?.nodes || []),
      mergeUser: {
        ...node.mergeRequest.mergeUser,
        id: getIdFromGraphQLId(node.mergeRequest.mergeUser?.id),
      },
      project: {
        ...node.mergeRequest.project,
        id: getIdFromGraphQLId(node.mergeRequest.project?.id),
        complianceFramework: node.mergeRequest.project?.complianceFrameworks?.nodes[0] || null,
      },
    },
    violatingUser: {
      ...node.violatingUser,
      id: getIdFromGraphQLId(node.violatingUser.id),
    },
  }));
};

export function mapProjects(nodes = []) {
  return nodes.map((node) => {
    return {
      ...node,
      complianceFrameworks: node.complianceFrameworks.nodes,
    };
  });
}
