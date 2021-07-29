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
