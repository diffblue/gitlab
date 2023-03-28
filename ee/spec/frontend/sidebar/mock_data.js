export const mockGroupPath = 'gitlab-org';
export const mockProjectPath = `${mockGroupPath}/some-project`;

export const mockIssue = {
  projectPath: mockProjectPath,
  iid: '1',
  groupPath: mockGroupPath,
};

export const mockIssueId = 'gid://gitlab/Issue/1';

export const mockCadence1 = {
  id: 'gid://gitlab/Iterations::Cadence/1',
  title: 'Plan cadence',
};

export const mockCadence2 = {
  id: 'gid://gitlab/Iterations::Cadence/2',
  title: 'Automatic cadence',
};

export const mockIteration1 = {
  __typename: 'Iteration',
  id: 'gid://gitlab/Iteration/1',
  title: null,
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/-/iterations/1',
  state: 'opened',
  startDate: '2021-10-05',
  dueDate: '2021-10-10',
  iterationCadence: mockCadence1,
};

export const mockIteration2 = {
  __typename: 'Iteration',
  id: 'gid://gitlab/Iteration/2',
  title: 'Awesome Iteration',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/-/iterations/2',
  state: 'opened',
  startDate: '2021-10-12',
  dueDate: '2021-10-17',
  iterationCadence: mockCadence2,
};

export const mockEpic1 = {
  __typename: 'Epic',
  id: 'gid://gitlab/Epic/1',
  title: 'Foobar Epic',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/-/epics/1',
  state: 'opened',
};

export const mockEpic2 = {
  __typename: 'Epic',
  id: 'gid://gitlab/Epic/2',
  title: 'Awesome Epic',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/-/epics/2',
  state: 'opened',
};

export const mockGroupIterationsResponse = {
  data: {
    workspace: {
      id: '1',
      attributes: {
        nodes: [mockIteration1, mockIteration2],
      },
      __typename: 'IterationConnection',
    },
    __typename: 'Group',
  },
};

export const mockGroupEpicsResponse = {
  data: {
    workspace: {
      id: '1',
      attributes: {
        nodes: [mockEpic1, mockEpic2],
      },
      __typename: 'EpicConnection',
    },
    __typename: 'Group',
  },
};

export const emptyGroupEpicsResponse = {
  data: {
    workspace: {
      id: '1',
      attributes: {
        nodes: [],
      },
      __typename: 'EpicConnection',
    },
    __typename: 'Group',
  },
};

export const mockCurrentIterationResponse1 = {
  data: {
    errors: [],
    workspace: {
      id: '1',
      issuable: {
        id: mockIssueId,
        attribute: mockIteration1,
        __typename: 'Issue',
      },
      __typename: 'Project',
    },
  },
};

export const mockCurrentIterationResponse2 = {
  data: {
    errors: [],
    workspace: {
      id: '1',
      issuable: {
        id: mockIssueId,
        attribute: mockIteration2,
        __typename: 'Issue',
      },
      __typename: 'Project',
    },
  },
};

export const noCurrentEpicResponse = {
  data: {
    workspace: {
      id: '1',
      issuable: { id: mockIssueId, hasEpic: false, attribute: null, __typename: 'Issue' },
      __typename: 'Project',
    },
  },
};

export const mockEpicUpdatesSubscriptionResponse = {
  data: {
    issuableEpicUpdated: null,
  },
};

export const mockNoPermissionEpicResponse = {
  data: {
    workspace: {
      id: '1',
      issuable: { id: mockIssueId, hasEpic: true, attribute: null, __typename: 'Issue' },
      __typename: 'Project',
    },
  },
};

export const mockEpicMutationResponse = {
  data: {
    issuableSetAttribute: {
      errors: [],
      issuable: {
        id: 'gid://gitlab/Issue/1',
        attribute: {
          id: 'gid://gitlab/Epic/2',
          title: 'Awesome Epic',
          state: 'opened',
          __typename: 'Epic',
        },
        __typename: 'Issue',
      },
      __typename: 'IssueSetEpicPayload',
    },
  },
};

export const epicAncestorsResponse = () => ({
  data: {
    workspace: {
      id: '1',
      __typename: 'Group',
      issuable: {
        __typename: 'Epic',
        id: 'gid://gitlab/Epic/4',
        ancestors: {
          nodes: [
            {
              id: 'gid://gitlab/Epic/2',
              title: 'Ancestor epic',
              url: 'http://gdk.test:3000/groups/gitlab-org/-/epics/2',
              state: 'opened',
              hasParent: false,
            },
          ],
        },
      },
    },
  },
});

export const issueNoWeightResponse = () => ({
  data: {
    workspace: {
      id: '1',
      issuable: { id: mockIssueId, weight: null, __typename: 'Issue' },
      __typename: 'Project',
    },
  },
});

export const issueWeightResponse = () => ({
  data: {
    workspace: {
      id: '1',
      issuable: { id: mockIssueId, weight: 0, __typename: 'Issue' },
      __typename: 'Project',
    },
  },
});

export const setWeightResponse = () => ({
  data: {
    issuableSetWeight: {
      issuable: { id: mockIssueId, weight: 2, __typename: 'Issue' },
      errors: [],
      __typename: 'Project',
    },
  },
});

export const removeWeightResponse = () => ({
  data: {
    issuableSetWeight: {
      issuable: { id: mockIssueId, weight: null, __typename: 'Issue' },
      errors: [],
      __typename: 'Project',
    },
  },
});

export const issueWeightSubscriptionResponse = () => ({
  data: {
    issuableWeightUpdated: {
      issue: {
        id: 'gid://gitlab/Issue/4',
        weight: 1,
      },
    },
  },
});

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
