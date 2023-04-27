import StatusToken from 'ee/requirements/components/tokens/status_token.vue';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';

export const mockUserPermissions = {
  updateRequirement: true,
  adminRequirement: true,
};

export const mockAuthor = {
  id: 'user-1',
  name: 'Administrator',
  username: 'root',
  avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  webUrl: 'http://0.0.0.0:3000/root',
};

export const mockTestReport = {
  id: 'gid://gitlab/RequirementsManagement::TestReport/1',
  state: 'PASSED',
  createdAt: '2020-06-04T10:55:48Z',
  __typename: 'TestReport',
};

export const mockTestReportFailed = {
  id: 'gid://gitlab/RequirementsManagement::TestReport/1',
  state: 'FAILED',
  createdAt: '2020-06-04T10:55:48Z',
  __typename: 'TestReport',
};

export const mockTestReportMissing = {
  id: 'gid://gitlab/RequirementsManagement::TestReport/1',
  state: 'MISSING',
  createdAt: '2020-06-04T10:55:48Z',
  __typename: 'TestReport',
};

export const requirement1 = {
  id: 'req-1',
  iid: '1',
  title: 'Virtutis, magnitudinis animi, patientiae, fortitudinis fomentis dolor mitigari solet.',
  titleHtml:
    'Virtutis, magnitudinis animi, patientiae, fortitudinis fomentis dolor mitigari solet.',
  description: 'fortitudinis _fomentis_ dolor mitigari solet.',
  descriptionHtml: 'fortitudinis <i>fomentis</i> dolor mitigari solet.',
  createdAt: '2020-03-19T08:09:09Z',
  updatedAt: '2020-03-20T08:09:09Z',
  state: 'OPENED',
  userPermissions: mockUserPermissions,
  author: mockAuthor,
  lastTestReportState: 'PASSED',
  lastTestReportManuallyCreated: false,
  satisfied: true,
  testReports: {
    nodes: [mockTestReport],
  },
  workItemIid: '1',
};

export const requirement2 = {
  id: 'req-2',
  iid: '2',
  title: 'Est autem officium, quod ita factum est, ut eius facti probabilis ratio reddi possit.',
  titleHtml:
    'Est autem officium, quod ita factum est, ut eius facti probabilis ratio reddi possit.',
  description: 'ut eius facti _probabilis_ ratio reddi possit.',
  descriptionHtml: 'ut eius facti <i>probabilis</i> ratio reddi possit.',
  createdAt: '2020-03-19T08:08:14Z',
  updatedAt: '2020-03-20T08:08:14Z',
  state: 'OPENED',
  userPermissions: mockUserPermissions,
  author: mockAuthor,
  lastTestReportState: 'FAILED',
  lastTestReportManuallyCreated: true,
  satisfied: false,
  testReports: {
    nodes: [mockTestReport],
  },
  workItemIid: '2',
};

export const requirement3 = {
  id: 'req-3',
  iid: '3',
  title: 'Non modo carum sibi quemque, verum etiam vehementer carum esse',
  titleHtml: 'Non modo carum sibi quemque, verum etiam vehementer carum esse',
  description: 'verum etiam _vehementer_ carum esse.',
  descriptionHtml: 'verum etiam <i>vehementer</i> carum esse.',
  createdAt: '2020-03-19T08:08:25Z',
  updatedAt: '2020-03-20T08:08:25Z',
  state: 'OPENED',
  userPermissions: mockUserPermissions,
  author: mockAuthor,
  lastTestReportState: null,
  lastTestReportManuallyCreated: true,
  satisfied: false,
  testReports: {
    nodes: [mockTestReport],
  },
  workItemIid: '3',
};

export const requirementArchived = {
  id: 'req-arch',
  iid: '23',
  title: 'Cuius quidem, quoniam Stoicus fuit',
  titleHtml: 'Cuius quidem, quoniam Stoicus fuit',
  description: 'quoniam _Stoicus_ fuit.',
  descriptionHtml: 'quoniam <i>Stoicus</i> fuit.',
  createdAt: '2020-03-31T13:31:40Z',
  updatedAt: '2020-03-31T13:31:40Z',
  state: 'ARCHIVED',
  userPermissions: mockUserPermissions,
  author: mockAuthor,
  lastTestReportState: null,
  lastTestReportManuallyCreated: true,
  satisfied: false,
  testReports: {
    nodes: [mockTestReport],
  },
  workItemIid: '23',
};

export const mockRequirementsOpen = [requirement1, requirement2, requirement3];

export const mockRequirementsArchived = [requirementArchived];

export const mockRequirementsAll = [...mockRequirementsOpen, ...mockRequirementsArchived];

export const mockRequirementsCount = {
  OPENED: 3,
  ARCHIVED: 1,
  ALL: 4,
};

export const mockPageInfo = {
  startCursor: 'eyJpZCI6IjI1IiwiY3JlYXRlZF9hdCI6IjIwMjAtMDMtMzEgMTM6MzI6MTQgVVRDIn0',
  endCursor: 'eyJpZCI6IjIxIiwiY3JlYXRlZF9hdCI6IjIwMjAtMDMtMzEgMTM6MzE6MTUgVVRDIn0',
};

export const mockFilters = [
  {
    type: TOKEN_TYPE_AUTHOR,
    value: { data: 'root' },
  },
  {
    type: TOKEN_TYPE_AUTHOR,
    value: { data: 'john.doe' },
  },
  {
    type: TOKEN_TYPE_STATUS,
    value: { data: 'satisfied' },
  },
  {
    type: FILTERED_SEARCH_TERM,
    value: { data: 'foo' },
  },
];

export const mockAuthorToken = {
  type: TOKEN_TYPE_AUTHOR,
  icon: 'user',
  title: TOKEN_TITLE_AUTHOR,
  unique: false,
  symbol: '@',
  token: UserToken,
  operators: OPERATORS_IS,
  fetchPath: 'gitlab-org/gitlab-shell',
  fetchUsers: expect.any(Function),
};

export const mockStatusToken = {
  type: TOKEN_TYPE_STATUS,
  icon: 'status',
  title: TOKEN_TITLE_STATUS,
  unique: true,
  token: StatusToken,
  operators: OPERATORS_IS,
};

/*
  Mock data used for testing with mock apollo client
*/

export const mockInitialRequirementCounts = {
  ARCHIVED: 0,
  OPENED: 1,
  ALL: 1,
};

export const mockProjectRequirementCounts = {
  data: {
    project: {
      id: '1',
      requirementStatesCount: {
        opened: mockInitialRequirementCounts.OPENED,
        archived: mockInitialRequirementCounts.ARCHIVED,
        __typename: 'RequirementStatesCount',
      },
      __typename: 'Project',
    },
  },
};

const mockUser = {
  ...mockAuthor,
  id: 'gid://gitlab/User/1',
  __typename: 'User',
};

export const mockTestReportConnectionPassed = {
  nodes: [mockTestReport],
  __typename: 'TestReportConnection',
};

export const mockTestReportConnectionFailed = {
  nodes: [mockTestReportFailed],
  __typename: 'TestReportConnection',
};

export const mockEmptyTestReportConnection = {
  nodes: [],
  __typename: 'TestReportConnection',
};

const projectRequirementBase = {
  __typename: 'Requirement',
  id: 'req-2',
  iid: '1',
  title: 'Requirement 1',
  titleHtml: 'Requirement 1',
  description: '',
  descriptionHtml: '',
  createdAt: '2021-03-15T05:24:32Z',
  updatedAt: '2021-03-15T05:24:32Z',
  state: 'OPENED',
  userPermissions: {
    updateRequirement: true,
    adminRequirement: true,
    __typename: 'RequirementPermissions',
  },
  author: {
    ...mockUser,
  },
  workItemIid: '1',
};

export const mockProjectRequirementFailed = {
  ...projectRequirementBase,
  lastTestReportState: 'FAILED',
  lastTestReportManuallyCreated: true,
  testReports: {
    ...mockTestReportConnectionFailed,
  },
};

export const mockProjectRequirementPassed = {
  ...projectRequirementBase,
  lastTestReportState: 'PASSED',
  lastTestReportManuallyCreated: true,
  testReports: {
    ...mockTestReportConnectionPassed,
  },
};

export const mockUpdateRequirementTitle = {
  data: {
    updateRequirement: {
      clientMutationId: null,
      errors: [],
      requirement: {
        ...mockProjectRequirementPassed,
        title: 'edited title',
      },
      __typename: 'UpdateRequirementPayload',
    },
  },
};

export const mockUpdateRequirementToFailed = {
  data: {
    updateRequirement: {
      clientMutationId: null,
      errors: [],
      requirement: {
        ...mockProjectRequirementFailed,
      },
      __typename: 'UpdateRequirementPayload',
    },
  },
};

const mockRequirementConnection = {
  nodes: [],
  pageInfo: {
    __typename: 'PageInfo',
    hasNextPage: false,
    hasPreviousPage: false,
    startCursor: 'eyJpZCI6',
    endCursor: 'eyJpZCI6I',
  },
  __typename: 'RequirementConnection',
};

export const mockProjectRequirements = {
  data: {
    project: {
      id: '1',
      requirements: {
        ...mockRequirementConnection,
        nodes: [{ ...mockProjectRequirementPassed }],
      },
      __typename: 'Project',
    },
  },
};
