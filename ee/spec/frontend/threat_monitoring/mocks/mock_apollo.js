import { mockAlertDetails, mockAlerts, mockPageInfo } from './mock_data';

export const getAlertsQuerySpy = jest.fn().mockResolvedValue({
  data: { project: { alertManagementAlerts: { nodes: mockAlerts, pageInfo: mockPageInfo } } },
});

export const emptyGetAlertsQuerySpy = jest.fn().mockResolvedValue({
  data: {
    project: {
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
  data: { project: { alertManagementAlerts: { nodes: [mockAlertDetails] } } },
});

export const getAlertDetailsQueryErrorMessage =
  'Variable $fullPath of type ID! was provided invalid value';

export const erroredGetAlertDetailsQuerySpy = jest.fn().mockResolvedValue({
  errors: [{ message: getAlertDetailsQueryErrorMessage }],
});

export const networkPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      project: {
        networkPolicies: {
          nodes,
        },
      },
    },
  });

export const scanExecutionPolicies = (nodes) =>
  jest.fn().mockResolvedValue({
    data: {
      project: {
        scanExecutionPolicies: {
          nodes,
        },
      },
    },
  });

export const mockAssignSecurityPolicyProjectResponses = {
  success: jest.fn().mockResolvedValue({ data: { securityPolicyProjectAssign: { errors: [] } } }),
  failure: jest
    .fn()
    .mockResolvedValue({ data: { securityPolicyProjectAssign: { errors: ['mutation failed'] } } }),
};
