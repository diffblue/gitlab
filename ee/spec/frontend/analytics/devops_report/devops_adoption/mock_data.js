export const groupData = [
  { id: '1', full_name: 'Foo' },
  { id: '2', full_name: 'Bar' },
];

export const groupNodes = [
  {
    __typename: 'Group',
    full_name: 'Foo',
    id: '1',
  },
  {
    __typename: 'Group',
    full_name: 'Bar',
    id: '2',
  },
];

export const groupNodeLabelValues = [
  { label: 'Foo', value: '1' },
  { label: 'Bar', value: '2' },
];

export const groupIds = [1, 2];

export const groupGids = ['gid://gitlab/Group/1', 'gid://gitlab/Group/2'];

export const devopsAdoptionNamespaceData = {
  nodes: [
    {
      id: 1,
      namespace: {
        fullName: 'Group 1',
        id: 'gid://gitlab/Group/1',
      },
      latestSnapshot: {
        issueOpened: true,
        mergeRequestOpened: true,
        mergeRequestApproved: false,
        runnerConfigured: true,
        pipelineSucceeded: false,
        deploySucceeded: false,
        codeOwnersUsedCount: 0,
        sastEnabledCount: 0,
        dastEnabledCount: 0,
        recordedAt: '2020-10-31T23:59:59Z',
        __typename: 'latestSnapshot',
      },
      __typename: 'devopsAdoptionEnabledNamespace',
    },
    {
      id: 2,
      namespace: {
        fullName: 'Group 2',
        id: 'gid://gitlab/Group/2',
      },
      latestSnapshot: null,
      __typename: 'devopsAdoptionEnabledNamespace',
    },
  ],
  __typename: 'devopsAdoptionEnabledNamespaces',
};

export const devopsAdoptionTableHeaders = [
  {
    index: 0,
    label: 'Group',
    tooltip: null,
  },
  {
    index: 1,
    label: 'Approvals',
    tooltip: 'At least one approval on a merge request',
  },
  {
    index: 2,
    label: 'Code owners',
    tooltip: 'Code owners enabled for at least one project',
  },
  {
    index: 3,
    label: 'Issues',
    tooltip: 'At least one issue opened',
  },
  {
    index: 4,
    label: 'MRs',
    tooltip: 'At least one merge request opened',
  },
  {
    index: 5,
    label: '',
    tooltip: null,
  },
];

export const genericErrorMessage = 'An error occurred while saving changes. Please try again.';

export const dataErrorMessage = 'Name already taken.';

export const genericDeleteErrorMessage =
  'An error occurred while removing the group. Please try again.';

export const overallAdoptionData = {
  displayMeta: false,
  featureMeta: [
    {
      adopted: false,
      title: 'Approvals',
    },
    {
      adopted: false,
      title: 'Code owners',
    },
    {
      adopted: true,
      title: 'Issues',
    },
    {
      adopted: true,
      title: 'MRs',
    },
    {
      adopted: false,
      title: 'DAST',
    },
    {
      adopted: false,
      title: 'SAST',
    },
    {
      adopted: false,
      title: 'Deploys',
    },
    {
      adopted: false,
      title: 'Pipelines',
    },
    {
      adopted: true,
      title: 'Runners',
    },
  ],
  icon: 'tanuki',
  title: 'Overall adoption',
  variant: 'primary',
};
