/* global List */

import Vue from 'vue';
import '~/boards/models/list';

export const mockLabel = {
  id: 'gid://gitlab/GroupLabel/121',
  title: 'To Do',
  color: '#F0AD4E',
  textColor: '#FFFFFF',
  description: null,
};

export const mockLists = [
  {
    id: 'gid://gitlab/List/1',
    title: 'Backlog',
    position: null,
    listType: 'backlog',
    collapsed: false,
    label: null,
    maxIssueCount: 0,
    assignee: null,
    milestone: null,
    preset: true,
  },
  {
    id: 'gid://gitlab/List/2',
    title: 'To Do',
    position: 0,
    listType: 'label',
    collapsed: false,
    label: mockLabel,
    maxIssueCount: 0,
    assignee: null,
    milestone: null,
    preset: false,
  },
  {
    id: 'gid://gitlab/List/3',
    title: 'Assignee list',
    position: 0,
    listType: 'assignee',
    collapsed: false,
    label: null,
    maxIssueCount: 0,
    assignee: {
      id: 'gid://gitlab/',
    },
    milestone: null,
    preset: false,
  },
  {
    id: 'gid://gitlab/List/4',
    title: 'Milestone list',
    position: 0,
    listType: 'milestone',
    collapsed: false,
    label: null,
    maxIssueCount: 0,
    assignee: null,
    milestone: {
      id: 'gid://gitlab/Milestone/1',
      title: 'A milestone',
    },
    preset: false,
  },
];

export const mockListsWithModel = mockLists.map((listMock) =>
  Vue.observable(new List({ ...listMock, doNotFetchIssues: true })),
);

const defaultDescendantCounts = {
  openedIssues: 0,
  closedIssues: 0,
};

export const mockAssignees = [
  {
    id: 'gid://gitlab/User/2',
    username: 'angelina.herman',
    name: 'Bernardina Bosco',
    avatar: 'https://www.gravatar.com/avatar/eb7b664b13a30ad9f9ba4b61d7075470?s=80&d=identicon',
    webUrl: 'http://127.0.0.1:3000/angelina.herman',
  },
  {
    id: 'gid://gitlab/User/118',
    username: 'jacklyn.moore',
    name: 'Brock Jaskolski',
    avatar: 'https://www.gravatar.com/avatar/af29c072d9fcf315772cfd802c7a7d35?s=80&d=identicon',
    webUrl: 'http://127.0.0.1:3000/jacklyn.moore',
  },
];

export const mockMilestones = [
  {
    id: 'gid://gitlab/Milestone/1',
    title: 'Milestone 1',
  },
  {
    id: 'gid://gitlab/Milestone/2',
    title: 'Milestone 2',
  },
];

export const mockIterations = [
  {
    id: 'gid://gitlab/Iteration/1',
    title: 'Iteration 1',
  },
  {
    id: 'gid://gitlab/Iteration/2',
    title: 'Iteration 2',
  },
];

export const labels = [
  {
    id: 'gid://gitlab/GroupLabel/5',
    title: 'Cosync',
    color: '#34ebec',
    description: null,
  },
];

export const rawIssue = {
  title: 'Issue 1',
  id: 'gid://gitlab/Issue/436',
  iid: 27,
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  referencePath: 'gitlab-org/test-subgroup/gitlab-test#27',
  path: '/gitlab-org/test-subgroup/gitlab-test/-/issues/27',
  labels: {
    nodes: [
      {
        id: 1,
        title: 'test',
        color: 'red',
        description: 'testing',
      },
    ],
  },
  assignees: {
    nodes: mockAssignees,
  },
  epic: {
    id: 'gid://gitlab/Epic/41',
  },
};

export const mockIssueGroupPath = 'gitlab-org';
export const mockIssueProjectPath = `${mockIssueGroupPath}/gitlab-test`;

export const mockIssue = {
  id: '436',
  fullId: 'gid://gitlab/Issue/436',
  iid: '27',
  title: 'Issue 1',
  referencePath: `${mockIssueProjectPath}#27`,
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  path: `/${mockIssueProjectPath}/-/issues/27`,
  assignees: mockAssignees,
  labels,
  epic: {
    id: 'gid://gitlab/Epic/41',
    iid: 2,
    group: { fullPath: mockIssueGroupPath },
  },
};

export const mockIssue2 = {
  id: '437',
  iid: 28,
  title: 'Issue 2',
  referencePath: '#28',
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/28',
  assignees: mockAssignees,
  labels,
  epic: {
    id: 'gid://gitlab/Epic/40',
    iid: 1,
    group: { fullPath: 'gitlab-org' },
  },
};

export const mockIssue3 = {
  id: 'gid://gitlab/Issue/438',
  iid: 29,
  title: 'Issue 3',
  referencePath: '#29',
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/28',
  assignees: mockAssignees,
  labels,
  epic: null,
};

export const mockIssue4 = {
  id: 'gid://gitlab/Issue/439',
  iid: 30,
  title: 'Issue 4',
  referencePath: '#30',
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/28',
  assignees: mockAssignees,
  labels,
  epic: null,
};

export const mockIssues = [mockIssue, mockIssue2];

export const mockEpic = {
  id: 'gid://gitlab/Epic/41',
  iid: '1',
  title: 'Epic title',
  state: 'opened',
  webUrl: '/groups/gitlab-org/-/epics/1',
  group: { fullPath: 'gitlab-org' },
  descendantCounts: {
    openedIssues: 3,
    closedIssues: 2,
  },
  issues: [mockIssue],
  labels: [],
};

export const mockFormattedBoardEpic = {
  fullId: 'gid://gitlab/Epic/41',
  id: 41,
  iid: '1',
  title: 'Epic title',
  state: 'opened',
  webUrl: '/groups/gitlab-org/-/epics/1',
  group: { fullPath: 'gitlab-org' },
  descendantCounts: {
    openedIssues: 3,
    closedIssues: 2,
  },
  issues: [mockIssue],
  labels: [],
};

export const mockEpics = [
  {
    id: 'gid://gitlab/Epic/41',
    iid: 2,
    description: null,
    title: 'Another marketing',
    group_id: 56,
    group_name: 'Marketing',
    group_full_name: 'Gitlab Org / Marketing',
    start_date: '2017-12-26',
    end_date: '2018-03-10',
    web_url: '/groups/gitlab-org/marketing/-/epics/2',
    descendantCounts: defaultDescendantCounts,
    hasParent: true,
    parent: {
      id: '40',
    },
    labels: [],
  },
  {
    id: 'gid://gitlab/Epic/40',
    iid: 1,
    description: null,
    title: 'Marketing epic',
    group_id: 56,
    group_name: 'Marketing',
    group_full_name: 'Gitlab Org / Marketing',
    start_date: '2017-12-25',
    end_date: '2018-03-09',
    web_url: '/groups/gitlab-org/marketing/-/epics/1',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
    labels: [],
  },
  {
    id: 'gid://gitlab/Epic/39',
    iid: 12,
    description: null,
    title: 'Epic with end in first timeframe month',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2017-04-02',
    end_date: '2017-11-30',
    web_url: '/groups/gitlab-org/-/epics/12',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
    labels: [],
  },
  {
    id: 'gid://gitlab/Epic/38',
    iid: 11,
    description: null,
    title: 'Epic with end date out of range',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2018-01-15',
    end_date: '2020-01-03',
    web_url: '/groups/gitlab-org/-/epics/11',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
    labels: [],
  },
  {
    id: 'gid://gitlab/Epic/37',
    iid: 10,
    description: null,
    title: 'Epic with timeline in same month',
    group_id: 2,
    group_name: 'Gitlab Org',
    group_full_name: 'Gitlab Org',
    start_date: '2018-01-01',
    end_date: '2018-01-31',
    web_url: '/groups/gitlab-org/-/epics/10',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
    labels: [],
  },
];

export const mockIssuesByListId = {
  'gid://gitlab/List/1': [mockIssue.id, mockIssue3.id, mockIssue4.id],
  'gid://gitlab/List/2': mockIssues.map(({ id }) => id),
};

export const issues = {
  [mockIssue.id]: mockIssue,
  [mockIssue2.id]: mockIssue2,
  [mockIssue3.id]: mockIssue3,
  [mockIssue4.id]: mockIssue4,
};
