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
  scopedPath: '/groups/top-level-group/-/iterations/4',
  iterationCadence: {
    __typename: 'IterationCadence',
    id: 'gid://gitlab/Iterations::Cadence/72',
    automatic: true,
  },
  __typename: 'Iteration',
};

export const mockManualIterationNode = {
  ...mockIterationNode,
  iterationCadence: {
    __typename: 'IterationCadence',
    id: 'gid://gitlab/Iterations::Cadence/72',
    automatic: false,
  },
};

export const mockIterationNodeWithoutTitle = {
  ...mockIterationNode,
  title: null,
};

export const createMockGroupIterations = (mockIteration = mockIterationNode) => {
  return {
    data: {
      group: {
        id: 'gid://gitlab/Group/114',
        iterations: {
          nodes: [mockIteration],
          __typename: 'IterationConnection',
        },
        __typename: 'Group',
      },
    },
  };
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
  __typename: 'IterationCadence',
  active: true,
  id: `gid://gitlab/Iterations::Cadence/72`,
  title: 'A manually-scheduled iteration cadence',
  automatic: false,
  rollOver: false,
  durationInWeeks: 2,
  description: null,
  startDate: '2020-06-28',
  iterationsInAdvance: 0,
};

export const automaticIterationCadence = {
  __typename: 'IterationCadence',
  active: true,
  id: `gid://gitlab/Iterations::Cadence/72`,
  title: 'An automatically-scheduled iteration cadence',
  automatic: true,
  rollOver: false,
  durationInWeeks: 3,
  description: 'The words',
  startDate: '2020-06-28',
  iterationsInAdvance: 2,
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
      __typename: 'Group',
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

export const readManualCadenceSuccess = {
  data: {
    group: {
      id: 'gid://gitlab/Group/114',
      iterationCadences: {
        nodes: [manualIterationCadence],
      },
    },
  },
};

export const mockIterationsWithoutCadences = [
  {
    id: 1,
    title: 'iteration 1',
    startDate: '2021-11-23T12:34:56',
    dueDate: '2021-11-30T12:34:56',
  },
  {
    id: 2,
    title: 'iteration 2',
    startDate: '2021-11-23T12:34:56',
    dueDate: '2021-11-30T12:34:56',
  },
];

export const mockIterationsWithCadences = [
  {
    id: 1,
    title: 'iteration 1',
    startDate: '2021-11-23T12:34:56',
    dueDate: '2021-11-30T12:34:56',
    iterationCadence: {
      id: 1,
      title: 'cadence 1',
    },
  },
  {
    id: 2,
    title: 'iteration 2',
    startDate: '2021-11-23T12:34:56',
    dueDate: '2021-11-30T12:34:56',
    iterationCadence: {
      id: 2,
      title: 'cadence 2',
    },
  },
  {
    id: 3,
    title: 'iteration 3',
    startDate: '2021-11-23T12:34:56',
    dueDate: '2021-11-30T12:34:56',
    iterationCadence: {
      id: 2,
      title: 'cadence 2',
    },
  },
  {
    id: 4,
    title: 'iteration 4',
    startDate: '2021-11-23T12:34:56',
    dueDate: '2021-11-30T12:34:56',
    iterationCadence: {
      id: 1,
      title: 'cadence 1',
    },
  },
];
