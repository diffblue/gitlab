import { TEST_HOST } from 'helpers/test_constants';

const mockIteration = {
  title: 'Iteration 1',
  __typename: 'Iteration',
};

const mockLabels = {
  count: 1,
  nodes: [
    {
      id: 'gid://gitlab/GroupLabel/25',
      color: '#5fa752',
      title: 'label',
      description: null,
      __typename: 'Label',
    },
  ],
  __typename: 'LabelConnection',
};

const createIssue = (values) => {
  return {
    state: 'closed',
    epic: {
      iid: 12345,
      __typename: 'Epic',
    },
    labels: {
      count: 0,
      nodes: [],
      __typename: 'LabelConnection',
    },
    milestone: {
      title: '11.1',
      __typename: 'Milestone',
    },
    iteration: null,
    weight: '3',
    dueDate: '2020-10-08',
    assignees: {
      count: 0,
      nodes: [],
      __typename: 'UserCoreConnection',
    },
    author: {
      name: 'Administrator',
      webUrl: 'link-to-author',
      avatarUrl: 'link-to-avatar',
      __typename: 'UserCore',
    },
    webUrl: `issues/${values.iid}`,
    iid: values.iid,
    ...values,
    __typename: 'Issue',
  };
};

export const mockIssuesApiResponse = [
  createIssue({ iid: 12345, title: 'Issue-1', createdAt: '2020-01-08' }),
  createIssue({ iid: 23456, title: 'Issue-2', createdAt: '2020-01-07', labels: mockLabels }),
  createIssue({ iid: 34567, title: 'Issue-3', createdAt: '2020-01-6', iteration: mockIteration }),
];

export const tableHeaders = [
  'Issue',
  'Age',
  'Status',
  'Milestone',
  'Iteration',
  'Weight',
  'Due date',
  'Assignees',
  'Created by',
];

export const endpoints = {
  api: `${TEST_HOST}/api`,
  issuesPage: `${TEST_HOST}/issues/page`,
};

export const getQueryIssuesAnalyticsResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/22',
      issues: {
        count: 3,
        nodes: mockIssuesApiResponse,
        __typename: 'IssueConnection',
      },
      __typename: 'Group',
    },
  },
};
