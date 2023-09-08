import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';

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

export const mockIssuesAnalyticsCountsStartDate = new Date('2023-07-01T00:00:00.000Z');
export const mockIssuesAnalyticsCountsEndDate = new Date('2023-08-01T00:00:00.000Z');

const generateMockIssuesAnalyticsCountsQuery = (
  isProject = false,
) => `query ($fullPath: ID!, $assigneeUsernames: [String!], $authorUsername: String, $milestoneTitle: String, $labelNames: [String!]) {
  issuesAnalyticsCountsData: ${isProject ? 'project' : 'group'}(fullPath: $fullPath) {
    id
    issuesOpened: flowMetrics {
      Jul_2023: issueCount(
        from: "2023-07-01"
        to: "2023-08-01"
        assigneeUsernames: $assigneeUsernames
        authorUsername: $authorUsername
        milestoneTitle: $milestoneTitle
        labelNames: $labelNames
      ) {
        value
      }
      Aug_2023: issueCount(
        from: "2023-08-01"
        to: "2023-09-01"
        assigneeUsernames: $assigneeUsernames
        authorUsername: $authorUsername
        milestoneTitle: $milestoneTitle
        labelNames: $labelNames
      ) {
        value
      }
    }
    issuesClosed: flowMetrics {
      Jul_2023: issuesCompletedCount(
        from: "2023-07-01"
        to: "2023-08-01"
        assigneeUsernames: $assigneeUsernames
        authorUsername: $authorUsername
        milestoneTitle: $milestoneTitle
        labelNames: $labelNames
      ) {
        value
      }
      Aug_2023: issuesCompletedCount(
        from: "2023-08-01"
        to: "2023-09-01"
        assigneeUsernames: $assigneeUsernames
        authorUsername: $authorUsername
        milestoneTitle: $milestoneTitle
        labelNames: $labelNames
      ) {
        value
      }
    }
  }
}
`;

export const mockGroupIssuesAnalyticsCountsQuery = generateMockIssuesAnalyticsCountsQuery();

export const mockProjectIssuesAnalyticsCountsQuery = generateMockIssuesAnalyticsCountsQuery(true);

export const generateMockIssuesAnalyticsCountsResponseData = (isProject = false) => ({
  id: 'fake-id',
  issuesOpened: {
    Jul_2023: {
      value: 134,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    Aug_2023: {
      value: 21,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    __typename: isProject
      ? 'ProjectValueStreamAnalyticsFlowMetrics'
      : 'GroupValueStreamAnalyticsFlowMetrics',
  },
  issuesClosed: {
    Jul_2023: {
      value: 110,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    Aug_2023: {
      value: 1,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    __typename: isProject
      ? 'ProjectValueStreamAnalyticsFlowMetrics'
      : 'GroupValueStreamAnalyticsFlowMetrics',
  },
  __typename: isProject ? TYPENAME_PROJECT : TYPENAME_GROUP,
});

export const mockGroupIssuesAnalyticsCountsResponseData = generateMockIssuesAnalyticsCountsResponseData();

export const mockProjectIssuesAnalyticsCountsResponseData = generateMockIssuesAnalyticsCountsResponseData(
  true,
);

export const generateMockIssuesAnalyticsCountsEmptyResponseData = (isProject = false) => ({
  id: 'fake-id',
  issuesOpened: {
    Jul_2023: {
      value: 0,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    Aug_2023: {
      value: 0,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    __typename: isProject
      ? 'ProjectValueStreamAnalyticsFlowMetrics'
      : 'GroupValueStreamAnalyticsFlowMetrics',
  },
  issuesClosed: {
    Jul_2023: {
      value: 0,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    Aug_2023: {
      value: 0,
      __typename: 'ValueStreamAnalyticsMetric',
    },
    __typename: isProject
      ? 'ProjectValueStreamAnalyticsFlowMetrics'
      : 'GroupValueStreamAnalyticsFlowMetrics',
  },
  __typename: isProject ? TYPENAME_PROJECT : TYPENAME_GROUP,
});

export const mockIssuesAnalyticsCountsChartData = [
  {
    name: 'Opened',
    data: [134, 21],
  },
  {
    name: 'Closed',
    data: [110, 1],
  },
];

export const mockOriginalFilters = {
  author_username: 'root',
  assignee_username: ['bob', 'smith'],
  label_name: ['Brest', 'DLT'],
  milestone_title: '16.4',
  months_back: '15',
};

export const mockFilters = {
  authorUsername: 'root',
  assigneeUsernames: ['bob', 'smith'],
  labelNames: ['Brest', 'DLT'],
  milestoneTitle: '16.4',
  monthsBack: '15',
};

export const mockEmptyFilters = {
  authorUsername: null,
  assigneeUsernames: null,
  labelNames: null,
  milestoneTitle: null,
  monthsBack: null,
};
