import { MERGE_REQUEST_VIOLATION_SEVERITY_LEVELS } from '../constants';

export const mapViolations = (nodes = []) => {
  return nodes.map((node) => ({
    ...node,
    mergeRequest: {
      ...node.mergeRequest,
      committers: node.mergeRequest.committers?.nodes || [],
      approvedByUsers: node.mergeRequest.approvedBy?.nodes || [],
      participants: node.mergeRequest.participants?.nodes || [],
    },
    project: {
      ...node.project,
      complianceFramework: node.project?.complianceFrameworks?.nodes[0] || null,
    },
    severity: MERGE_REQUEST_VIOLATION_SEVERITY_LEVELS[node.severity],
  }));
};
