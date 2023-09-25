import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import { TEST_HOST } from 'spec/test_constants';

export const mockInitialConfig = {
  epicsEndpoint: `${TEST_HOST}/epics`,
  issuesEndpoint: `${TEST_HOST}/issues`,
  projectsEndpoint: `${TEST_HOST}/projects`,
  autoCompleteEpics: true,
  autoCompleteIssues: false,
  userSignedIn: true,
  allowSubEpics: true,
  isShowingLabels: false,
  epicsWebUrl: `${TEST_HOST}/groups/gitlab-org/-/epics`,
  issuesWebUrl: `${TEST_HOST}/groups/gitlab-org/-/issues`,
};

export const mockParentItem = {
  id: 'gid://gitlab/Epic/42',
  iid: 1,
  numericalId: 1,
  fullPath: 'gitlab-org',
  groupName: 'GitLab Org',
  title: 'Some sample epic',
  reference: 'gitlab-org&1',
  type: 'Epic',
  hasChildren: true,
  hasIssues: true,
  userPermissions: {
    canAdmin: true,
    createEpic: true,
    canAdminRelation: true,
  },
  descendantCounts: {
    openedEpics: 1,
    closedEpics: 1,
    openedIssues: 2,
    closedIssues: 1,
  },
  healthStatus: {
    issuesOnTrack: 1,
    issuesAtRisk: 0,
    issuesNeedingAttention: 1,
  },
  labels: {
    nodes: [
      {
        color: '#ff0000',
        description: 'Mock Label',
        textColor: '#ffffff',
        title: 'Label',
      },
    ],
  },
};

export const mockParentItem2 = {
  id: 'gid://gitlab/Epic/43',
  iid: 2,
  fullPath: 'gitlab-org',
  title: 'Some sample epic 2',
  reference: 'gitlab-org&2',
  parentReference: 'gitlab-org&2',
  userPermissions: {
    canAdmin: true,
    createEpic: true,
    canAdminRelation: true,
  },
  descendantCounts: {
    openedEpics: 1,
    closedEpics: 1,
    openedIssues: 1,
    closedIssues: 1,
  },
  healthStatus: {
    issuesOnTrack: 1,
    issuesAtRisk: 0,
    issuesNeedingAttention: 1,
  },
  labels: {
    nodes: [
      {
        color: '#ff0000',
        description: 'Mock Label',
        textColor: '#ffffff',
        title: 'Label',
      },
    ],
  },
};

export const mockEpic1 = {
  id: 'gid://gitlab/Epic/4',
  iid: '4',
  title: 'Quo ea ipsa enim perferendis at omnis officia.',
  state: STATUS_OPEN,
  webPath: '/groups/gitlab-org/-/epics/4',
  reference: '&4',
  relationPath: '/groups/gitlab-org/-/epics/1/links/4',
  createdAt: '2019-02-18T14:13:06Z',
  closedAt: null,
  hasChildren: true,
  hasIssues: true,
  userPermissions: {
    canAdmin: true,
    createEpic: true,
  },
  group: {
    fullPath: 'gitlab-org',
  },
  healthStatus: {
    issuesAtRisk: 0,
    issuesNeedingAttention: 0,
    issuesOnTrack: 0,
  },
  labels: {
    nodes: [
      {
        color: '#ff0000',
        description: 'Mock Label',
        textColor: '#ffffff',
        title: 'Label',
      },
    ],
  },
};

export const mockEpic2 = {
  id: 'gid://gitlab/Epic/3',
  iid: '3',
  title: 'A nisi mollitia explicabo quam soluta dolor hic.',
  state: STATUS_CLOSED,
  webPath: '/groups/gitlab-org/-/epics/3',
  reference: '&3',
  relationPath: '/groups/gitlab-org/-/epics/1/links/3',
  createdAt: '2019-02-18T14:13:06Z',
  closedAt: '2019-04-26T06:51:22Z',
  hasChildren: false,
  hasIssues: false,
  userPermissions: {
    canAdmin: true,
    createEpic: true,
  },
  group: {
    fullPath: 'gitlab-org',
  },
  healthStatus: {
    issuesAtRisk: 0,
    issuesNeedingAttention: 0,
    issuesOnTrack: 0,
  },
  labels: {
    nodes: [
      {
        color: '#ff0000',
        description: 'Mock Label',
        textColor: '#ffffff',
        title: 'Label',
      },
    ],
  },
};

// Epic meta data for having some open issues
export const mockEpicMeta1 = {
  descendantCounts: {
    openedEpics: 1,
    closedEpics: 1,
    openedIssues: 2,
    closedIssues: 1,
  },
  healthStatus: {
    issuesOnTrack: 1,
    issuesAtRisk: 0,
    issuesNeedingAttention: 1,
  },
};

// Epic meta data for having no open issues
export const mockEpicMeta2 = {
  descendantCounts: {
    openedEpics: 0,
    closedEpics: 1,
    openedIssues: 0,
    closedIssues: 2,
  },
  healthStatus: {
    issuesOnTrack: 0,
    issuesAtRisk: 0,
    issuesNeedingAttention: 0,
  },
};

// Epic meta data for having no child issues
export const mockEpicMeta3 = {
  descendantCounts: {
    openedEpics: 0,
    closedEpics: 1,
    openedIssues: 0,
    closedIssues: 0,
  },
  healthStatus: {
    issuesOnTrack: 0,
    issuesAtRisk: 0,
    issuesNeedingAttention: 0,
  },
};

export const mockDefaultProjectForIssueCreation = {
  id: 'gid://gitlab/Project/1',
  nameWithNamespace: 'gitlab-org',
};

export const mockIssue1 = {
  iid: '8',
  epicIssueId: 'gid://gitlab/EpicIssue/3',
  title: 'Nostrum cum mollitia quia recusandae fugit deleniti voluptatem delectus.',
  closedAt: null,
  state: STATUS_OPEN,
  createdAt: '2019-02-18T14:06:41Z',
  confidential: true,
  dueDate: '2019-06-14',
  weight: 5,
  webPath: '/gitlab-org/gitlab-shell/issues/8',
  reference: 'gitlab-org/gitlab-shell#8',
  relationPath: '/groups/gitlab-org/-/epics/1/issues/10',
  assignees: {
    edges: [
      {
        node: {
          webUrl: 'http://127.0.0.1:3001/root',
          name: 'Administrator',
          username: 'root',
          avatarUrl:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        },
      },
    ],
  },
  milestone: {
    title: 'v4.0',
    startDate: '2019-02-01',
    dueDate: '2019-06-30',
  },
  healthStatus: 'onTrack',
  labels: {
    nodes: [
      {
        color: '#ff0000',
        description: 'Mock Label',
        textColor: '#ffffff',
        title: 'Label',
      },
    ],
  },
};

export const mockIssue2 = {
  iid: '33',
  epicIssueId: 'gid://gitlab/EpicIssue/4',
  title: 'Dismiss Cipher with no integrity',
  closedAt: null,
  state: STATUS_OPEN,
  createdAt: '2019-02-18T14:13:05Z',
  confidential: false,
  dueDate: null,
  weight: null,
  webPath: '/gitlab-org/gitlab-shell/issues/33',
  reference: 'gitlab-org/gitlab-shell#33',
  relationPath: '/groups/gitlab-org/-/epics/1/issues/27',
  assignees: {
    edges: [],
  },
  milestone: null,
  healthStatus: 'needsAttention',
  labels: {
    nodes: [],
  },
};

export const mockClosedIssue = {
  iid: '42',
  epicIssueId: 'gid://gitlab/EpicIssue/5',
  title: 'View closed issues in epic',
  closedAt: null,
  state: STATUS_CLOSED,
  createdAt: '2019-02-18T14:13:05Z',
  confidential: false,
  dueDate: null,
  weight: null,
  webPath: '/gitlab-org/gitlab-shell/issues/42',
  reference: 'gitlab-org/gitlab-shell#42',
  relationPath: '/groups/gitlab-org/-/epics/1/issues/27',
  assignees: {
    edges: [],
  },
  milestone: null,
  healthStatus: 'atRisk',
  labels: {
    nodes: [],
  },
};

export const mockEpics = [mockEpic1, mockEpic2];

export const mockIssues = [mockIssue1, mockIssue2, mockClosedIssue];

export const mockQueryResponse = {
  data: {
    group: {
      id: 1,
      path: 'gitlab-org',
      fullPath: 'gitlab-org',
      epic: {
        id: 1,
        iid: 1,
        title: 'Foo bar',
        webPath: '/groups/gitlab-org/-/epics/1',
        userPermissions: {
          adminEpic: true,
          createEpic: true,
        },
        children: {
          edges: [
            {
              node: mockEpic1,
            },
            {
              node: mockEpic2,
            },
          ],
          pageInfo: {
            endCursor: 'abc',
            hasNextPage: true,
          },
        },
        issues: {
          edges: [
            {
              node: mockIssue1,
            },
            {
              node: mockIssue2,
            },
            {
              node: mockClosedIssue,
            },
          ],
          pageInfo: {
            endCursor: 'def',
            hasNextPage: true,
          },
        },
        descendantCounts: mockParentItem.descendantCounts,
        descendantWeightSum: {
          openedIssues: 10,
          closedIssues: 5,
        },
        healthStatus: {
          atRisk: 0,
          needsAttention: 1,
          onTrack: 1,
        },
        defaultProjectForIssueCreation: mockDefaultProjectForIssueCreation,
      },
    },
  },
};

export const mockQueryResponse2 = {
  data: {
    group: {
      id: 1,
      path: 'gitlab-org',
      fullPath: 'gitlab-org',
      epic: {
        id: 1,
        iid: 1,
        title: 'Foo bar',
        webPath: '/groups/gitlab-org/-/epics/1',
        userPermissions: {
          adminEpic: true,
          createEpic: true,
        },
        children: {
          edges: [
            {
              node: mockEpic1,
            },
            {
              node: mockEpic2,
            },
          ],
          pageInfo: {
            endCursor: 'abc',
            hasNextPage: true,
          },
        },
        issues: {
          edges: [
            {
              node: mockClosedIssue,
            },
            {
              node: mockIssue1,
            },
            {
              node: mockIssue2,
            },
          ],
          pageInfo: {
            endCursor: 'def',
            hasNextPage: true,
          },
        },
      },
    },
  },
};

export const mockReorderMutationResponse = {
  epicTreeReorder: {
    clientMutationId: null,
    errors: [],
    __typename: 'EpicTreeReorderPayload',
  },
};

export const mockEpicTreeReorderInput = {
  baseEpicId: 'gid://gitlab/Epic/1',
  moved: {
    id: 'gid://gitlab/Epic/2',
    moveAfterId: 'gid://gitlab/Epic/3',
  },
};

export const mockFrequentlyUsedProjects = [
  {
    id: 1,
    name: 'Project 1',
    namespace: 'Gitlab / Project 1',
    webUrl: '/gitlab-org/project1',
    avatarUrl: null,
    lastAccessedOn: 123,
    frequency: 4,
  },
  {
    id: 2,
    name: 'Project 2',
    namespace: 'Gitlab / Project 2',
    webUrl: '/gitlab-org/project2',
    avatarUrl: null,
    lastAccessedOn: 124,
    frequency: 3,
  },
];

export const mockMixedFrequentlyUsedProjects = [
  {
    id: 1,
    name: 'Project 1',
    namespace: 'Gitlab / Project 1',
    webUrl: '/gitlab-org/project1',
    avatarUrl: null,
    lastAccessedOn: 123,
    frequency: 4,
  },
  {
    id: 2,
    name: 'Project 2',
    namespace: 'Gitlab.com / Project 2',
    webUrl: '/gitlab-com/project2',
    avatarUrl: null,
    lastAccessedOn: 124,
    frequency: 3,
  },
];

export const mockRoadmapAppData = {
  epics_path: '/groups/group1/-/epics.json?parent_id=1',
  group_id: '2',
  iid: '1',
  full_path: 'group1',
  empty_state_illustration: '',
  new_epic_path: '/groups/group1/-/epics/new',
  list_epics_path: '/groups/group1/-/epics',
  epics_docs_path: '/help/user/group/epics/index',
  preset_type: 'MONTHS',
  epics_state: 'all',
  sorted_by: 'start_date_asc',
  inner_height: '600',
  child_epics: 'true',
};
