import { GlFilteredSearchToken } from '@gitlab/ui';
import {
  OPERATORS_IS_NOT,
  OPERATORS_IS,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_RELEASE,
  TOKEN_TITLE_TYPE,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_WEIGHT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import EmojiToken from '~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import {
  TOKEN_TITLE_EPIC,
  TOKEN_TITLE_HEALTH,
  TOKEN_TITLE_ITERATION,
  TOKEN_TITLE_WEIGHT,
} from 'ee/vue_shared/components/filtered_search_bar/constants';
import EpicToken from 'ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import IterationToken from 'ee/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue';
import ReleaseToken from '~/vue_shared/components/filtered_search_bar/tokens/release_token.vue';
import WeightToken from 'ee/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';
import HealthToken from 'ee/vue_shared/components/filtered_search_bar/tokens/health_token.vue';
import { mockLabelList } from 'jest/boards/mock_data';

export const mockEpicBoard = {
  id: 'gid://gitlab/Board::EpicBoard/1',
  name: 'Development',
  labels: {
    nodes: [{ id: 'gid://gitlab/Label/32', title: 'Deliverable' }],
  },
};

export const mockEpicBoardResponse = {
  data: {
    workspace: {
      id: 'gid://gitlab/Group/114',
      board: mockEpicBoard,
      __typename: 'Group',
    },
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
  totalTimeSpent: 0,
  humanTimeEstimate: null,
  humanTotalTimeSpent: null,
  emailsDisabled: false,
  hidden: false,
  webUrl: 'http://127.0.0.1:3000/gitlab-org/gitlab-shell/-/issues/32',
  relativePosition: 0,
  type: 'ISSUE',
  severity: 'UNKNOWN',
  milestone: null,
  weight: null,
  confidential: false,
  referencePath: 'gitlab-org/test-subgroup/gitlab-test#27',
  path: '/gitlab-org/test-subgroup/gitlab-test/-/issues/27',
  blocked: false,
  blockedByCount: 0,
  healthStatus: null,
  iteration: null,
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
  __typename: 'Issue',
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

export const mockListWithIteration = {
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
  iteration: {
    id: 'gid://gitlab/Iteration/1',
    title: null,
    iterationCadence: mockIterationCadence,
    startDate: '2021-10-05',
    dueDate: '2021-10-10',
    __typename: 'Iteration',
  },
};

export const mockIssueInListWithIteration = {
  id: 'gid://gitlab/Issue/438',
  iid: 29,
  title: 'Issue 5',
  referencePath: '#29',
  dueDate: null,
  timeEstimate: 0,
  weight: null,
  confidential: false,
  path: '/gitlab-org/gitlab-test/-/issues/28',
  assignees: mockAssignees,
  labels,
  epic: null,
  list: mockListWithIteration,
};

export const mockIssues = [mockIssue, mockIssue2];

export const mockGroupIssuesResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      board: {
        id: 'gid://gitlab/Board/1',
        lists: {
          nodes: [
            {
              id: 'gid://gitlab/List/1',
              listType: 'backlog',
              issues: {
                nodes: [rawIssue],
                pageInfo: {
                  endCursor: null,
                  hasNextPage: false,
                },
              },
            },
          ],
        },
      },
      __typename: 'Group',
    },
  },
};

export const mockProjectIssuesResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      board: {
        id: 'gid://gitlab/Board/1',
        lists: {
          nodes: [
            {
              id: 'gid://gitlab/List/1',
              listType: 'backlog',
              issues: {
                nodes: [rawIssue],
                pageInfo: {
                  endCursor: null,
                  hasNextPage: false,
                },
              },
            },
          ],
        },
      },
      __typename: 'Project',
    },
  },
};

export const rawEpic = {
  id: 'gid://gitlab/Epic/41',
  iid: '1',
  title: 'Epic title',
  state: 'opened',
  webPath: '/groups/gitlab-org/-/epics/1',
  webUrl: '/groups/gitlab-org/-/epics/1',
  group: { id: 'gid://gitlab/Group/1', fullPath: 'gitlab-org' },
  reference: '&41',
  referencePath: 'gitlab-org/gitlab-subgroup&41',
  relativePosition: '1',
  confidential: false,
  subscribed: false,
  blocked: false,
  blockedByCount: 0,
  hasIssues: true,
  createdAt: '2023-01-20T02:21:29Z',
  closedAt: '2023-01-20T02:21:29Z',
  descendantCounts: {
    openedIssues: 3,
    closedIssues: 2,
    closedEpics: 0,
    openedEpics: 0,
  },
  descendantWeightSum: {
    openedIssues: 0,
    closedIssues: 0,
  },
  issues: [rawIssue],
  labels: [],
  __typename: 'Epic',
};

export const mockEpic = {
  id: 'gid://gitlab/Epic/41',
  iid: '1',
  title: 'Epic title',
  state: 'opened',
  webUrl: '/groups/gitlab-org/-/epics/1',
  group: { fullPath: 'gitlab-org' },
  referencePath: 'gitlab-org/gitlab-subgroup&41',
  relativePosition: '1',
  confidential: false,
  subscribed: false,
  blocked: false,
  blockedByCount: 0,
  hasIssues: true,
  descendantCounts: {
    openedIssues: 3,
    closedIssues: 2,
    closedEpics: 0,
    openedEpics: 0,
  },
  descendantWeightSum: {
    openedIssues: 0,
    closedIssues: 0,
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
    referencePath: 'gitlab-org/marketing&2',
    web_url: '/groups/gitlab-org/marketing/-/epics/2',
    descendantCounts: defaultDescendantCounts,
    hasParent: true,
    parent: {
      id: '40',
    },
    labels: [],
    userPreferences: {
      collapsed: false,
    },
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
    referencePath: 'gitlab-org/marketing&1',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
    labels: [],
    userPreferences: {
      collapsed: false,
    },
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
    referencePath: 'gitlab-org&12',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
    labels: [],
    userPreferences: {
      collapsed: false,
    },
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
    referencePath: 'gitlab-org&11',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
    labels: [],
    userPreferences: {
      collapsed: false,
    },
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
    referencePath: 'gitlab-org&10',
    descendantCounts: defaultDescendantCounts,
    hasParent: false,
    labels: [],
    userPreferences: {
      collapsed: false,
    },
  },
];

export const mockGroupEpicsResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      board: {
        id: 'gid://gitlab/Boards::EpicBoard/1',
        lists: {
          nodes: [
            {
              id: 'gid://gitlab/Boards::EpicList/4',
              listType: 'backlog',
              epics: {
                nodes: [rawEpic],
                pageInfo: {
                  endCursor: null,
                  hasNextPage: false,
                },
              },
              __typename: 'EpicList',
            },
          ],
        },
        __typename: 'EpicBoard',
      },
      __typename: 'Group',
    },
  },
};

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
  fetchUsers,
  fetchMilestones,
  fetchIterations,
  fetchIterationCadences,
) => [
  {
    icon: 'user',
    title: TOKEN_TITLE_ASSIGNEE,
    type: TOKEN_TYPE_ASSIGNEE,
    operators: OPERATORS_IS_NOT,
    token: UserToken,
    unique: true,
    fetchUsers,
    preloadedUsers: [],
  },
  {
    icon: 'pencil',
    title: TOKEN_TITLE_AUTHOR,
    type: TOKEN_TYPE_AUTHOR,
    operators: OPERATORS_IS_NOT,
    symbol: '@',
    token: UserToken,
    unique: true,
    fetchUsers,
    preloadedUsers: [],
  },
  {
    icon: 'labels',
    title: TOKEN_TITLE_LABEL,
    type: TOKEN_TYPE_LABEL,
    operators: OPERATORS_IS_NOT,
    token: LabelToken,
    unique: false,
    symbol: '~',
    fetchLabels,
  },
  {
    type: TOKEN_TYPE_MY_REACTION,
    icon: 'thumb-up',
    title: TOKEN_TITLE_MY_REACTION,
    unique: true,
    token: EmojiToken,
    fetchEmojis: expect.any(Function),
  },
  {
    type: TOKEN_TYPE_CONFIDENTIAL,
    icon: 'eye-slash',
    title: TOKEN_TITLE_CONFIDENTIAL,
    unique: true,
    token: GlFilteredSearchToken,
    operators: OPERATORS_IS,
    options: [
      { icon: 'eye-slash', value: 'yes', title: 'Yes' },
      { icon: 'eye', value: 'no', title: 'No' },
    ],
  },
  {
    icon: 'clock',
    title: TOKEN_TITLE_MILESTONE,
    symbol: '%',
    type: TOKEN_TYPE_MILESTONE,
    token: MilestoneToken,
    shouldSkipSort: true,
    unique: true,
    fetchMilestones,
  },
  {
    icon: 'issues',
    title: TOKEN_TITLE_TYPE,
    type: TOKEN_TYPE_TYPE,
    token: GlFilteredSearchToken,
    unique: true,
    options: [
      { icon: 'issue-type-issue', value: 'ISSUE', title: 'Issue' },
      { icon: 'issue-type-incident', value: 'INCIDENT', title: 'Incident' },
    ],
  },
  {
    type: TOKEN_TYPE_RELEASE,
    title: TOKEN_TITLE_RELEASE,
    icon: 'rocket',
    token: ReleaseToken,
    fetchReleases: expect.any(Function),
  },
  {
    type: TOKEN_TYPE_EPIC,
    icon: 'epic',
    title: TOKEN_TITLE_EPIC,
    unique: true,
    symbol: '&',
    token: EpicToken,
    idProperty: 'id',
    useIdValue: true,
    fullPath: 'gitlab-org',
  },
  {
    type: TOKEN_TYPE_ITERATION,
    icon: 'iteration',
    title: TOKEN_TITLE_ITERATION,
    operators: OPERATORS_IS_NOT,
    unique: true,
    fetchIterations,
    fetchIterationCadences,
    token: IterationToken,
  },
  {
    type: TOKEN_TYPE_WEIGHT,
    icon: 'weight',
    title: TOKEN_TITLE_WEIGHT,
    token: WeightToken,
    unique: true,
  },
  {
    type: TOKEN_TYPE_HEALTH,
    icon: 'status-health',
    title: TOKEN_TITLE_HEALTH,
    token: HealthToken,
    unique: false,
    operators: OPERATORS_IS_NOT,
  },
];

export const mockEpicSwimlanesResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/114',
      board: {
        id: 'gid://gitlab/Board/1',
        epics: {
          nodes: [mockEpics],
          pageInfo: {
            endCursor: null,
            hasNextPage: false,
          },
        },
      },
      __typename: 'Group',
    },
  },
};

export const mockUpdateListWipLimitResponse = {
  data: {
    boardListUpdateLimitMetrics: {
      list: mockLabelList,
      errors: [],
      __typename: 'BoardListUpdateLimitMetricsPayload',
    },
  },
};

const mockEpicLabelList = {
  id: 'gid://gitlab/Boards::EpicList/2',
  title: 'To Do',
  position: 0,
  listType: 'label',
  collapsed: false,
  label: {
    id: 'gid://gitlab/GroupLabel/121',
    title: 'To Do',
    color: '#F0AD4E',
    textColor: '#FFFFFF',
    description: null,
    descriptionHtml: null,
    __typename: 'Label',
  },
  metadata: {
    epicsCount: 10,
    totalWeight: 33,
  },
  __typename: 'EpicList',
};

export const epicBoardListsQueryResponse = {
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      board: {
        id: 'gid://gitlab/Boards::EpicBoard/1',
        hideBacklogList: false,
        lists: {
          nodes: [mockEpicLabelList],
        },
      },
      __typename: 'Group',
    },
  },
};
