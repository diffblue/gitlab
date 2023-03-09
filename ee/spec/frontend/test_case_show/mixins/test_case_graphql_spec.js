import { shallowMount } from '@vue/test-utils';

import TestCaseShowRoot from 'ee/test_case_show/components/test_case_show_root.vue';
import markTestCaseTodoDone from 'ee/test_case_show/queries/mark_test_case_todo_done.mutation.graphql';
import moveTestCase from 'ee/test_case_show/queries/move_test_case.mutation.graphql';
import updateTestCase from 'ee/test_case_show/queries/update_test_case.mutation.graphql';
import { mockCurrentUserTodo } from 'jest/vue_shared/issuable/list/mock_data';

import Api from '~/api';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';

import { mockProvide, mockTestCase } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

const createComponent = ({ testCase, testCaseQueryLoading = false } = {}) =>
  shallowMount(TestCaseShowRoot, {
    provide: {
      ...mockProvide,
    },
    mocks: {
      $apollo: {
        queries: {
          testCase: {
            loading: testCaseQueryLoading,
            refetch: jest.fn(),
          },
        },
        mutate: jest.fn(),
      },
    },
    data() {
      return {
        testCaseLoading: testCaseQueryLoading,
        testCase: testCaseQueryLoading
          ? {}
          : {
              ...mockTestCase,
              ...testCase,
            },
      };
    },
  });

describe('TestCaseGraphQL Mixin', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('updateTestCase', () => {
    it('calls `$apollo.mutate` with updateTestCase mutation and updateTestCaseInput variables', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({
        data: {
          updateIssue: {
            errors: [],
            issue: mockTestCase,
          },
        },
      });

      wrapper.vm.updateTestCase({
        variables: {
          title: 'Foo',
        },
        errorMessage: 'Something went wrong',
      });

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updateTestCase,
        variables: {
          input: {
            projectPath: mockProvide.projectFullPath,
            iid: mockProvide.testCaseId,
            title: 'Foo',
          },
        },
      });
    });

    it('calls `createAlert` with errorMessage on promise reject', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue({});

      return wrapper.vm
        .updateTestCase({
          variables: {
            title: 'Foo',
          },
          errorMessage: 'Something went wrong',
        })
        .then(() => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'Something went wrong',
            captureError: true,
            error: expect.any(Object),
          });
        });
    });
  });

  describe('addTestCaseAsTodo', () => {
    it('sets `testCaseTodoUpdateInProgress` to true', () => {
      jest.spyOn(Api, 'addProjectIssueAsTodo').mockResolvedValue({});

      wrapper.vm.addTestCaseAsTodo();

      expect(wrapper.vm.testCaseTodoUpdateInProgress).toBe(true);
    });

    it('calls `Api.addProjectIssueAsTodo` method with params `projectFullPath` and `testCaseId`', () => {
      jest.spyOn(Api, 'addProjectIssueAsTodo').mockResolvedValue({});

      wrapper.vm.addTestCaseAsTodo();

      expect(Api.addProjectIssueAsTodo).toHaveBeenCalledWith(
        mockProvide.projectFullPath,
        mockProvide.testCaseId,
      );
    });

    it('calls `$apollo.queries.testCase.refetch` method on request promise resolve', () => {
      jest.spyOn(Api, 'addProjectIssueAsTodo').mockResolvedValue({});
      jest.spyOn(wrapper.vm.$apollo.queries.testCase, 'refetch');

      return wrapper.vm.addTestCaseAsTodo().then(() => {
        expect(wrapper.vm.$apollo.queries.testCase.refetch).toHaveBeenCalled();
      });
    });

    it('calls `createAlert` method on request promise reject', () => {
      jest.spyOn(Api, 'addProjectIssueAsTodo').mockRejectedValue({});

      return wrapper.vm.addTestCaseAsTodo().then(() => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while adding test case to a to-do item.',
          captureError: true,
          error: expect.any(Object),
        });
      });
    });

    it('sets `testCaseTodoUpdateInProgress` to false on request promise resolve or reject', () => {
      jest.spyOn(Api, 'addProjectIssueAsTodo').mockRejectedValue({});

      return wrapper.vm.addTestCaseAsTodo().finally(() => {
        expect(wrapper.vm.testCaseTodoUpdateInProgress).toBe(false);
      });
    });
  });

  describe('markTestCaseTodoDone', () => {
    const todoResolvedMutation = {
      data: {
        todoMarkDone: {
          errors: [],
        },
      },
    };

    it('sets `testCaseTodoUpdateInProgress` to true', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(todoResolvedMutation);

      wrapper.vm.markTestCaseTodoDone();

      expect(wrapper.vm.testCaseTodoUpdateInProgress).toBe(true);
    });

    it('calls `$apollo.mutate` with markTestCaseTodoDone mutation and todoMarkDoneInput variables', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(todoResolvedMutation);

      wrapper.vm.markTestCaseTodoDone();

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: markTestCaseTodoDone,
        variables: {
          todoMarkDoneInput: {
            id: mockCurrentUserTodo.id,
          },
        },
      });
    });

    it('calls `$apollo.queries.testCase.refetch` on mutation promise resolve', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(todoResolvedMutation);
      jest.spyOn(wrapper.vm.$apollo.queries.testCase, 'refetch');

      return wrapper.vm.markTestCaseTodoDone().then(() => {
        expect(wrapper.vm.$apollo.queries.testCase.refetch).toHaveBeenCalled();
      });
    });

    it('calls `createAlert` with errorMessage on mutation promise reject', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue({});

      return wrapper.vm.markTestCaseTodoDone().then(() => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while marking test case to-do item as done.',
          captureError: true,
          error: expect.any(Object),
        });
      });
    });

    it('sets `testCaseTodoUpdateInProgress` to false on mutation promise resolve or reject', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(todoResolvedMutation);

      return wrapper.vm.markTestCaseTodoDone().finally(() => {
        expect(wrapper.vm.testCaseTodoUpdateInProgress).toBe(false);
      });
    });
  });

  describe('moveTestCase', () => {
    const mockTargetProject = {
      full_path: 'gitlab-org/gitlab-shell',
    };
    const moveResolvedMutation = {
      data: {
        issueMove: {
          errors: [],
          issue: {
            webUrl: mockTestCase.webUrl,
          },
        },
      },
    };

    it('sets `testCaseMoveInProgress` to true', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(moveResolvedMutation);

      wrapper.vm.moveTestCase(mockTargetProject);

      expect(wrapper.vm.testCaseMoveInProgress).toBe(true);
    });

    it('calls `$apollo.mutate` with moveTestCase mutation and moveTestCaseInput variables', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(moveResolvedMutation);

      wrapper.vm.moveTestCase(mockTargetProject);

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: moveTestCase,
        variables: {
          moveTestCaseInput: {
            projectPath: mockProvide.projectFullPath,
            iid: mockProvide.testCaseId,
            targetProjectPath: mockTargetProject.full_path,
          },
        },
      });
    });

    it('calls `visitUrl` with updated test case URL on mutation promise resolve', async () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(moveResolvedMutation);

      await wrapper.vm.moveTestCase(mockTargetProject);

      expect(wrapper.vm.testCaseMoveInProgress).toBe(true);
      expect(visitUrl).toHaveBeenCalledWith(moveResolvedMutation.data.issueMove.issue.webUrl);
    });

    it('calls `createAlert` with errorMessage on mutation promise reject', async () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue({});

      await wrapper.vm.moveTestCase(mockTargetProject);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while moving test case.',
        captureError: true,
        error: expect.any(Object),
      });
      expect(wrapper.vm.testCaseMoveInProgress).toBe(false);
    });
  });
});
