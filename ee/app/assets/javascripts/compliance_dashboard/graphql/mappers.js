export const mapViolations = (nodes = []) => {
  return nodes.map((node) => ({
    ...node,
    mergeRequest: {
      ...node.mergeRequest,
      committers: node.mergeRequest.committers?.nodes || [],
      approvedByUsers: node.mergeRequest.approvedBy?.nodes || [],
      participants: node.mergeRequest.participants?.nodes || [],
      // TODO: Once the legacy dashboard is removed (https://gitlab.com/gitlab-org/gitlab/-/issues/346266) we can update the drawer to use the new attributes and remove these 2 mappings
      reference: node.mergeRequest.ref,
      mergedBy: node.mergeRequest.mergeUser,
      project: {
        ...node.mergeRequest.project,
        complianceFramework: node.mergeRequest.project?.complianceFrameworks?.nodes[0] || null,
      },
    },
  }));
};
