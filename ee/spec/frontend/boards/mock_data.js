import { GlFilteredSearchToken } from '@gitlab/ui';
import { __ } from '~/locale';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import EpicToken from 'ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import IterationToken from 'ee/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue';
import ReleaseToken from '~/vue_shared/components/filtered_search_bar/tokens/release_token.vue';
import WeightToken from 'ee/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';

export const mockEpicBoard = {
  id: 'gid://gitlab/Board::EpicBoard/1',
  name: 'Development',
  labels: {
    nodes: [{ id: 'gid://gitlab/Label/32', title: 'Deliverable' }],
  },
};

export const mockEpicBoardsResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/114',
      epicBoards: {
        nodes: [
          {
            id: 'gid://gitlab/Boards::EpicBoard/1',
            name: 'Development',
          },
          {
            id: 'gid://gitlab/Boards::EpicBoard/2',
            name: 'Marketing',
          },
        ],
      },
      __typename: 'Group',
    },
  },
};

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

export const mockIterationCadence = {
  id: 'gid://gitlab/Iterations::Cadence/1',
  title: 'GitLab.org Iterations',
  durationInWeeks: 1,
  __typename: 'IterationCadence',
};

export const mockIterations = [
  {
    id: 'gid://gitlab/Iteration/1',
    title: null,
    iterationCadence: mockIterationCadence,
    startDate: '2021-10-05',
    dueDate: '2021-10-10',
    __typename: 'Iteration',
  },
  {
    id: 'gid://gitlab/Iteration/2',
    title: 'Some iteration',
    iterationCadence: {
      id: 'gid://gitlab/Iterations::Cadence/2',
      title: 'GitLab.org Iterations: Volume II',
      durationInWeeks: 2,
      __typename: 'IterationCadence',
    },
    startDate: '2021-10-12',
    dueDate: '2021-10-17',
    __typename: 'Iteration',
  },
];

export const mockIterationsResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      iterations: {
        nodes: mockIterations,
      },
      __typename: 'Group',
    },
  },
};

export const mockIterationCadences = [
  {
    id: 'gid://gitlab/Iterations::Cadence/11',
    title: 'Cadence 1',
  },
  {
    id: 'gid://gitlab/Iterations::Cadence/22',
    title: 'Cadence 2',
  },
];

export const labels = [
  {
    id: 'gid://gitlab/GroupLabel/5',
    title: 'Cosync',
    color: '#34ebec',
    description: null,
  },
  {
    id: 'gid://gitlab/GroupLabel/6',
    title: 'Brock',
    color: '#e082b6',
    description: null,
  },
];

export const color = {
  color: '#ff0000',
  title: 'Red',
};

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
  id: 'gid://gitlab/Issue/436',
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
  id: 'gid://gitlab/Epic/41',
  iid: '1',
  title: 'Epic title',
  referencePath: 'gitlab-org/gitlab-subgroup&41',
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

export const mockGroup0 = {
  __typename: 'Group',
  id: 'gid://gitlab/Group/22',
  name: 'Gitlab Org',
  fullName: 'Gitlab Org',
  fullPath: 'gitlab-org',
};

export const mockGroup1 = {
  __typename: 'Group',
  id: 'gid://gitlab/Group/108',
  name: 'Design',
  fullName: 'Gitlab Org / Design',
  fullPath: 'gitlab-org/design',
};

export const mockGroup2 = {
  __typename: 'Group',
  id: 'gid://gitlab/Group/109',
  name: 'Database',
  fullName: 'Gitlab Org / Database',
  fullPath: 'gitlab-org/database',
};

export const mockSubGroups = [mockGroup0, mockGroup1, mockGroup2];

export const mockTokens = (
  fetchLabels,
  fetchAuthors,
  fetchMilestones,
  fetchIterations,
  fetchIterationCadences,
) => [
  {
    icon: 'user',
    title: __('Assignee'),
    type: 'assignee',
    operators: [
      { value: '=', description: 'is' },
      { value: '!=', description: 'is not' },
    ],
    token: AuthorToken,
    unique: true,
    fetchAuthors,
    preloadedAuthors: [],
  },
  {
    icon: 'pencil',
    title: __('Author'),
    type: 'author',
    operators: [
      { value: '=', description: 'is' },
      { value: '!=', description: 'is not' },
    ],
    symbol: '@',
    token: AuthorToken,
    unique: true,
    fetchAuthors,
    preloadedAuthors: [],
  },
  {
    icon: 'labels',
    title: __('Label'),
    type: 'label',
    operators: [
      { value: '=', description: 'is' },
      { value: '!=', description: 'is not' },
    ],
    token: LabelToken,
    unique: false,
    symbol: '~',
    fetchLabels,
  },
  {
    type: 'my-reaction',
    icon: 'thumb-up',
    title: 'My-Reaction',
    unique: true,
    token: EmojiToken,
    fetchEmojis: expect.any(Function),
  },
  {
    type: 'confidential',
    icon: 'eye-slash',
    title: 'Confidential',
    unique: true,
    token: GlFilteredSearchToken,
    operators: [{ value: '=', description: 'is' }],
    options: [
      { icon: 'eye-slash', value: 'yes', title: 'Yes' },
      { icon: 'eye', value: 'no', title: 'No' },
    ],
  },
  {
    icon: 'clock',
    title: __('Milestone'),
    symbol: '%',
    type: 'milestone',
    token: MilestoneToken,
    shouldSkipSort: true,
    unique: true,
    fetchMilestones,
  },
  {
    icon: 'issues',
    title: __('Type'),
    type: 'type',
    token: GlFilteredSearchToken,
    unique: true,
    options: [
      { icon: 'issue-type-issue', value: 'ISSUE', title: 'Issue' },
      { icon: 'issue-type-incident', value: 'INCIDENT', title: 'Incident' },
    ],
  },
  {
    type: 'release',
    title: __('Release'),
    icon: 'rocket',
    token: ReleaseToken,
    fetchReleases: expect.any(Function),
  },
  {
    type: 'epic',
    icon: 'epic',
    title: 'Epic',
    unique: true,
    symbol: '&',
    token: EpicToken,
    idProperty: 'id',
    useIdValue: true,
    fullPath: 'gitlab-org',
  },
  {
    type: 'iteration',
    icon: 'iteration',
    title: 'Iteration',
    operators: [
      { value: '=', description: 'is' },
      { value: '!=', description: 'is not' },
    ],
    unique: true,
    fetchIterations,
    fetchIterationCadences,
    token: IterationToken,
  },
  {
    type: 'weight',
    icon: 'weight',
    title: __('Weight'),
    token: WeightToken,
    unique: true,
  },
];
