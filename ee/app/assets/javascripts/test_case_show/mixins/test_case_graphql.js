import Api from '~/api';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

import markTestCaseTodoDone from '../queries/mark_test_case_todo_done.mutation.graphql';
import moveTestCase from '../queries/move_test_case.mutation.graphql';
import projectTestCase from '../queries/project_test_case.query.graphql';
import projectTestCaseTaskList from '../queries/test_case_tasklist.query.graphql';
import updateTestCase from '../queries/update_test_case.mutation.graphql';

export default {
  apollo: {
    testCase: {
      query: projectTestCase,
      variables() {
        return {
          projectPath: this.projectFullPath,
          testCaseId: this.testCaseId,
        };
      },
      update(data) {
        return data.project?.issue;
      },
      result() {
        this.testCaseLoading = false;
      },
      error(error) {
        this.testCaseLoading = false;
        this.testCaseLoadFailed = true;
        createAlert({
          message: s__('TestCases|Something went wrong while fetching test case.'),
          captureError: true,
          error,
        });
      },
    },
    taskCompletionStatus: {
      query: projectTestCaseTaskList,
      variables() {
        return {
          projectPath: this.projectFullPath,
          testCaseId: this.testCaseId,
        };
      },
      update(data) {
        return data.project?.issue?.taskCompletionStatus;
      },
      error(error) {
        createAlert({
          message: s__('TestCases|Something went wrong while updating the test case.'),
          captureError: true,
          error,
        });
      },
    },
  },
  data() {
    return {
      testCaseLoading: true,
      testCaseLoadFailed: false,
      testCaseTodoUpdateInProgress: false,
      testCaseMoveInProgress: false,
    };
  },
  methods: {
    updateTestCase({ variables, errorMessage }) {
      return this.$apollo
        .mutate({
          mutation: updateTestCase,
          variables: {
            input: {
              projectPath: this.projectFullPath,
              iid: this.testCaseId,
              ...variables,
            },
          },
        })
        .then(({ data = {} }) => {
          const errors = data.updateIssue?.errors;
          if (errors?.length) {
            throw new Error(`Error updating test case. Error message: ${errors[0].message}`);
          }
          return data.updateIssue?.issue;
        })
        .catch((error) => {
          createAlert({
            message: errorMessage,
            captureError: true,
            error,
          });
        });
    },
    /**
     * We're using Public REST API to add Test Case as a to-do item since
     * GraphQL mutation to do the same is unavailable as of now.
     */
    addTestCaseAsTodo() {
      this.testCaseTodoUpdateInProgress = true;
      return Api.addProjectIssueAsTodo(this.projectFullPath, this.testCaseId)
        .then(() => {
          this.$apollo.queries.testCase.refetch();
        })
        .catch((error) => {
          createAlert({
            message: s__('TestCases|Something went wrong while adding test case to a to-do item.'),
            captureError: true,
            error,
          });
        })
        .finally(() => {
          this.testCaseTodoUpdateInProgress = false;
        });
    },
    markTestCaseTodoDone() {
      this.testCaseTodoUpdateInProgress = true;
      return this.$apollo
        .mutate({
          mutation: markTestCaseTodoDone,
          variables: {
            todoMarkDoneInput: {
              id: this.todo.id,
            },
          },
        })
        .then(({ data = {} }) => {
          const errors = data.todoMarkDone?.errors;
          if (errors?.length) {
            throw new Error(`Error marking todo as done. Error message: ${errors[0].message}`);
          }
          this.$apollo.queries.testCase.refetch();
        })
        .catch((error) => {
          createAlert({
            message: s__(
              'TestCases|Something went wrong while marking test case to-do item as done.',
            ),
            captureError: true,
            error,
          });
        })
        .finally(() => {
          this.testCaseTodoUpdateInProgress = false;
        });
    },
    moveTestCase(targetProject) {
      this.testCaseMoveInProgress = true;
      return this.$apollo
        .mutate({
          mutation: moveTestCase,
          variables: {
            moveTestCaseInput: {
              projectPath: this.projectFullPath,
              iid: this.testCaseId,
              targetProjectPath: targetProject.full_path,
            },
          },
        })
        .then(({ data = {} }) => {
          if (!data.issueMove) return;

          const { errors } = data.issueMove;
          if (errors?.length) {
            throw new Error(`Error moving test case. Error message: ${errors[0].message}`);
          }
          visitUrl(data.issueMove?.issue.webUrl);
        })
        .catch((error) => {
          this.testCaseMoveInProgress = false;
          createAlert({
            message: s__('TestCases|Something went wrong while moving test case.'),
            captureError: true,
            error,
          });
        });
    },
  },
};
