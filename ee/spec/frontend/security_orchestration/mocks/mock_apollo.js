export const projectScanExecutionPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: {
        id: '3',
        __typename: 'Project',
        scanExecutionPolicies: {
          nodes,
        },
      },
    },
  });

export const groupScanExecutionPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: {
        id: '3',
        __typename: 'Group',
        scanExecutionPolicies: {
          nodes,
        },
      },
    },
  });

export const projectScanResultPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: {
        id: '3',
        __typename: 'Project',
        scanResultPolicies: {
          nodes,
        },
      },
    },
  });

export const groupScanResultPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      namespace: {
        id: '3',
        __typename: 'Group',
        scanResultPolicies: {
          nodes,
        },
      },
    },
  });

export const mockLinkSecurityPolicyProjectResponses = {
  success: jest.fn().mockResolvedValue({ data: { securityPolicyProjectAssign: { errors: [] } } }),
  failure: jest
    .fn()
    .mockResolvedValue({ data: { securityPolicyProjectAssign: { errors: ['mutation failed'] } } }),
};

export const mockUnlinkSecurityPolicyProjectResponses = {
  success: jest.fn().mockResolvedValue({ data: { securityPolicyProjectUnassign: { errors: [] } } }),
  failure: jest.fn().mockResolvedValue({
    data: { securityPolicyProjectUnassign: { errors: ['mutation failed'] } },
  }),
};
