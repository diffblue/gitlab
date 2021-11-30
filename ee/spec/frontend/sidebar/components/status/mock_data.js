export const getHealthStatusMutationResponse = ({ healthStatus = null }) => {
  return {
    data: {
      updateIssue: {
        issuable: { id: 'gid://gitlab/Issue/1', healthStatus, __typename: 'Issue' },
        errors: [],
        __typename: 'UpdateIssuePayload',
      },
    },
  };
};

export const getHealthStatusQueryResponse = ({ state = 'opened', healthStatus = null }) => {
  return {
    data: {
      workspace: {
        id: '1',
        issuable: { id: 'gid://gitlab/Issue/1', state, healthStatus, __typename: 'Issue' },
        __typename: 'Project',
      },
    },
  };
};
