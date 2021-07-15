export const mockGroupPath = 'gitlab-org';
export const mockProjectPath = `${mockGroupPath}/some-project`;

export const mockIssue = {
  projectPath: mockProjectPath,
  iid: '1',
  groupPath: mockGroupPath,
};

export const mockIssueId = 'gid://gitlab/Issue/1';

export const mockIteration1 = {
  __typename: 'Iteration',
  id: 'gid://gitlab/Iteration/1',
  title: 'Foobar Iteration',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/-/iterations/1',
  state: 'opened',
};

export const mockIteration2 = {
  __typename: 'Iteration',
  id: 'gid://gitlab/Iteration/2',
  title: 'Awesome Iteration',
  webUrl: 'http://gdk.test:3000/groups/gitlab-org/-/iterations/2',
  state: 'opened',
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
      iterations: {
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
      attributes: {
        nodes: [mockEpic1, mockEpic2],
      },
      __typename: 'EpicConnection',
    },
    __typename: 'Group',
  },
};

export const emptyGroupIterationsResponse = {
  data: {
    workspace: {
      iterations: {
        nodes: [],
      },
      __typename: 'IterationConnection',
    },
    __typename: 'Group',
  },
};

export const emptyGroupEpicsResponse = {
  data: {
    workspace: {
      attributes: {
        nodes: [],
      },
      __typename: 'EpicConnection',
    },
    __typename: 'Group',
  },
};

export const noCurrentIterationResponse = {
  data: {
    workspace: {
      issuable: { id: mockIssueId, iteration: null, __typename: 'Issue' },
      __typename: 'Project',
    },
  },
};

export const noCurrentEpicResponse = {
  data: {
    workspace: {
      issuable: { id: mockIssueId, attribute: null, __typename: 'Issue' },
      __typename: 'Project',
    },
  },
};

export const mockIterationMutationResponse = {
  data: {
    issuableSetIteration: {
      errors: [],
      issuable: {
        id: 'gid://gitlab/Issue/1',
        iteration: {
          id: 'gid://gitlab/Iteration/2',
          title: 'Awesome Iteration',
          state: 'opened',
          __typename: 'Iteration',
        },
        __typename: 'Issue',
      },
      __typename: 'IssueSetIterationPayload',
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
      issuable: { id: mockIssueId, weight: null, __typename: 'Issue' },
      __typename: 'Project',
    },
  },
});

export const issueWeightResponse = () => ({
  data: {
    workspace: {
      issuable: { id: mockIssueId, weight: 0, __typename: 'Issue' },
      __typename: 'Project',
    },
  },
});
