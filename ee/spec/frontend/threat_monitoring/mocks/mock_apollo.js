import { mockAlertDetails, mockAlerts, mockPageInfo } from './mock_data';

export const getAlertsQuerySpy = jest.fn().mockResolvedValue({
  data: {
    project: { id: '1', alertManagementAlerts: { nodes: mockAlerts, pageInfo: mockPageInfo } },
  },
});

export const emptyGetAlertsQuerySpy = jest.fn().mockResolvedValue({
  data: {
    project: {
      id: '1',
      alertManagementAlerts: {
        nodes: [],
        pageInfo: { endCursor: '', hasNextPage: false, hasPreviousPage: false, startCursor: '' },
      },
    },
  },
});

export const loadingQuerySpy = jest.fn().mockReturnValue(new Promise(() => {}));

export const apolloFailureResponse = jest.fn().mockRejectedValue();

export const getAlertDetailsQuerySpy = jest.fn().mockResolvedValue({
  data: { project: { id: '1', alertManagementAlerts: { nodes: [mockAlertDetails] } } },
});

export const getAlertDetailsQueryErrorMessage =
  'Variable $fullPath of type ID! was provided invalid value';

export const erroredGetAlertDetailsQuerySpy = jest.fn().mockResolvedValue({
  errors: [{ message: getAlertDetailsQueryErrorMessage }],
});

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

export const scanResultPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      project: {
        id: '3',
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
