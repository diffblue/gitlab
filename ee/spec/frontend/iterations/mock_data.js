export const mockIterationNode = {
  description: 'some description',
  descriptionHtml: '<p>some description</p>',
  dueDate: '2021-02-17',
  id: 'gid://gitlab/Iteration/4',
  iid: '1',
  startDate: '2021-02-10',
  state: 'upcoming',
  title: 'top-level-iteration',
  webPath: '/groups/top-level-group/-/iterations/4',
  __typename: 'Iteration',
};

export const mockGroupIterations = {
  data: {
    group: {
      id: 'gid://gitlab/Group/114',
      iterations: {
        nodes: [mockIterationNode],
        __typename: 'IterationConnection',
      },
      __typename: 'Group',
    },
  },
};

export const mockProjectIterations = {
  data: {
    project: {
      id: 'gid://gitlab/Project/114',
      iterations: {
        nodes: [mockIterationNode],
        __typename: 'IterationConnection',
      },
      __typename: 'Project',
    },
  },
};

export const manualIterationCadence = {
  id: `gid://gitlab/Iterations::Cadence/72`,
  title: 'A manual iteration cadence',
  automatic: true,
  rollOver: false,
  durationInWeeks: '3',
  description: 'The words',
  duration: '3',
  startDate: '2020-06-28',
  iterationsInAdvance: '2',
};

export const createMutationSuccess = {
  data: { iterationCreate: { iteration: mockIterationNode, errors: [] } },
};

export const createMutationFailure = {
  data: {
    iterationCreate: { iteration: mockIterationNode, errors: ['alas, your data is unchanged'] },
  },
};
export const updateMutationSuccess = {
  data: { updateIteration: { iteration: mockIterationNode, errors: [] } },
};

export const emptyGroupIterationsSuccess = {
  data: {
    workspace: {
      id: 'gid://gitlab/Group/114',
      iterations: {
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: '',
          endCursor: '',
        },
      },
    },
  },
};

export const nonEmptyGroupIterationsSuccess = {
  data: {
    workspace: {
      id: 1,
      iterations: {
        nodes: [
          {
            ...mockIterationNode,
            scopedPath: '/',
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: '',
          endCursor: '',
        },
      },
    },
  },
};

export const readCadenceSuccess = {
  data: {
    group: {
      id: 'gid://gitlab/Group/114',
      iterationCadences: {
        nodes: [manualIterationCadence],
      },
    },
  },
};
