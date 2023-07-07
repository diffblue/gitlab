import {
  mockAuthor,
  mockIssuable,
  mockCurrentUserTodo,
} from 'jest/vue_shared/issuable/list/mock_data';

// Remove attributes that are not used for test cases
const {
  assignees,
  iid,
  taskCompletionStatus,
  userDiscussionsCount,
  ...mockIssuableAttributes
} = mockIssuable;

export const mockTestCase = {
  ...mockIssuableAttributes,
  __typename: 'Issue',
  type: 'TEST_CASE',
  id: 'gid://gitlab/Issue/1',
  currentUserTodos: {
    nodes: [mockCurrentUserTodo],
  },
  moved: false,
  movedTo: null,
  updatedBy: mockAuthor,
};

export const mockTestCaseResponse = (testCase = mockTestCase) => {
  return {
    data: {
      project: {
        __typename: 'Project',
        id: 'gid://gitlab/Project/1',
        name: 'Gitlab Org',
        issue: testCase,
      },
    },
  };
};

export const mockTaskCompletionResponse = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      name: 'Gitlab Org',
      issue: { ...mockTestCase, taskCompletionStatus: null },
    },
  },
};

export const mockProvide = {
  projectFullPath: 'gitlab-org/gitlab-test',
  testCaseNewPath: '/gitlab-org/gitlab-test/-/quality/test_cases/new',
  testCasesPath: '/root/rails/-/quality/test_cases',
  testCaseId: mockIssuable.iid,
  canEditTestCase: true,
  canMoveTestCase: true,
  descriptionPreviewPath: '/gitlab-org/gitlab-test/preview_markdown',
  descriptionHelpPath: '/help/user/markdown',
  labelsFetchPath: '/gitlab-org/gitlab-test/-/labels.json',
  labelsManagePath: '/gitlab-org/gitlab-shell/-/labels',
  projectsFetchPath: '/-/autocomplete/projects?project_id=1',
  updatePath: `${mockIssuable.webUrl}.json`,
  lockVersion: 1,
};
