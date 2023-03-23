<script>
import {
  GlLoadingIcon,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlButton,
  GlSprintf,
  GlLink,
  GlAlert,
} from '@gitlab/ui';

import { STATUS_OPEN } from '~/issues/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import IssuableShow from '~/vue_shared/issuable/show/components/issuable_show_root.vue';
import IssuableEventHub from '~/vue_shared/issuable/show/event_hub';
import { s__, __ } from '~/locale';

import TestCaseGraphQL from '../mixins/test_case_graphql';
import TestCaseSidebar from './test_case_sidebar.vue';

const stateEvent = {
  Close: 'CLOSE',
  Reopen: 'REOPEN',
};

export default {
  components: {
    GlLoadingIcon,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlButton,
    GlSprintf,
    GlLink,
    GlAlert,
    IssuableShow,
    TestCaseSidebar,
  },
  mixins: [TestCaseGraphQL],
  inject: [
    'projectFullPath',
    'testCaseNewPath',
    'testCaseId',
    'updatePath',
    'lockVersion',
    'canEditTestCase',
    'descriptionPreviewPath',
    'descriptionHelpPath',
  ],
  data() {
    return {
      testCase: {},
      taskCompletionStatus: {},
      editTestCaseFormVisible: false,
      testCaseSaveInProgress: false,
      testCaseStateChangeInProgress: false,
      taskListUpdateFailed: false,
    };
  },
  computed: {
    isTestCaseOpen() {
      return this.testCase.state === STATUS_OPEN;
    },
    statusIcon() {
      return this.isTestCaseOpen ? 'issue-open-m' : 'mobile-issue-close';
    },
    statusBadgeText() {
      return this.isTestCaseOpen ? __('Open') : __('Archived');
    },
    testCaseActionTitle() {
      return this.isTestCaseOpen ? __('Archive test case') : __('Reopen test case');
    },
    todo() {
      const todos = this.testCase.currentUserTodos.nodes;

      return todos.length ? todos[0] : null;
    },
    selectedLabels() {
      return this.testCase.labels.nodes.map((label) => ({
        ...label,
        id: getIdFromGraphQLId(label.id),
      }));
    },
  },
  methods: {
    handleTestCaseStateChange() {
      this.testCaseStateChangeInProgress = true;
      return this.updateTestCase({
        variables: {
          stateEvent: this.isTestCaseOpen ? stateEvent.Close : stateEvent.Reopen,
        },
        errorMessage: s__('TestCases|Something went wrong while updating the test case.'),
      })
        .then((updatedTestCase) => {
          this.testCase = updatedTestCase;
        })
        .finally(() => {
          this.testCaseStateChangeInProgress = false;
        });
    },
    handleTaskListUpdateSuccess() {
      this.$apollo.queries.taskCompletionStatus.refetch();
    },
    handleTaskListUpdateFailure() {
      this.taskListUpdateFailed = true;
    },
    handleEditTestCase() {
      this.editTestCaseFormVisible = true;
    },
    handleSaveTestCase({ issuableTitle, issuableDescription }) {
      this.testCaseSaveInProgress = true;
      return this.updateTestCase({
        variables: {
          title: issuableTitle,
          description: issuableDescription,
        },
        errorMessage: s__('TestCases|Something went wrong while updating the test case.'),
      })
        .then((updatedTestCase) => {
          this.testCase = updatedTestCase;
          this.editTestCaseFormVisible = false;
          IssuableEventHub.$emit('update.issuable');
        })
        .finally(() => {
          this.testCaseSaveInProgress = false;
        });
    },
    handleCancelClick() {
      this.editTestCaseFormVisible = false;
      IssuableEventHub.$emit('close.form');
    },
    handleTestCaseUpdated(updatedTestCase) {
      this.testCase = updatedTestCase;
    },
  },
};
</script>

<template>
  <div class="test-case-container">
    <gl-alert v-if="taskListUpdateFailed" variant="danger" @dismiss="taskListUpdateFailed = false">
      {{
        __(
          'Someone edited this test case at the same time you did. The description has been updated and you will need to make your changes again.',
        )
      }}
    </gl-alert>
    <gl-loading-icon v-if="testCaseLoading" size="lg" class="gl-mt-3" />
    <issuable-show
      v-if="!testCaseLoading && !testCaseLoadFailed"
      :issuable="testCase"
      :status-icon="statusIcon"
      :enable-edit="canEditTestCase"
      :enable-autocomplete="true"
      :enable-task-list="true"
      :edit-form-visible="editTestCaseFormVisible"
      :description-preview-path="descriptionPreviewPath"
      :description-help-path="descriptionHelpPath"
      :task-completion-status="taskCompletionStatus"
      :task-list-update-path="updatePath"
      :task-list-lock-version="lockVersion"
      status-icon-class="gl-sm-display-none"
      show-work-item-type-icon
      @edit-issuable="handleEditTestCase"
      @task-list-update-success="handleTaskListUpdateSuccess"
      @task-list-update-failure="handleTaskListUpdateFailure"
    >
      <template #status-badge>
        <gl-sprintf
          v-if="testCase.moved"
          :message="__('Archived (%{movedToStart}moved%{movedToEnd})')"
        >
          <template #movedTo="{ content }">
            <gl-link :href="testCase.movedTo.webUrl" class="text-white text-underline">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
        <span v-else>{{ statusBadgeText }}</span>
      </template>
      <template #header-actions>
        <gl-dropdown
          v-if="canEditTestCase"
          data-testid="actions-dropdown"
          :text="__('Options')"
          :right="true"
          class="d-md-none gl-flex-grow-1"
        >
          <gl-dropdown-item>{{ testCaseActionTitle }}</gl-dropdown-item>
          <gl-dropdown-divider />
          <gl-dropdown-item :href="testCaseNewPath">{{ __('New test case') }}</gl-dropdown-item>
        </gl-dropdown>
        <gl-button
          v-if="canEditTestCase"
          data-testid="archive-test-case"
          class="d-none d-md-inline-block gl-mr-2"
          :loading="testCaseStateChangeInProgress"
          @click="handleTestCaseStateChange"
          >{{ testCaseActionTitle }}</gl-button
        >
        <gl-button
          data-testid="new-test-case"
          category="secondary"
          variant="confirm"
          class="d-md-inline-block"
          :class="{ 'd-none': canEditTestCase, 'gl-flex-grow-1': !canEditTestCase }"
          :href="testCaseNewPath"
          >{{ __('New test case') }}</gl-button
        >
      </template>
      <template #edit-form-actions="issuableMeta">
        <gl-button
          data-testid="save-test-case"
          :disable="testCaseSaveInProgress || !issuableMeta.issuableTitle.length"
          :loading="testCaseSaveInProgress"
          category="primary"
          variant="confirm"
          class="float-left"
          @click.prevent="handleSaveTestCase(issuableMeta)"
          >{{ __('Save changes') }}</gl-button
        >
        <gl-button
          data-testid="cancel-test-case-edit"
          class="float-right"
          @click="handleCancelClick"
        >
          {{ __('Cancel') }}
        </gl-button>
      </template>
      <template #right-sidebar-items="{ sidebarExpanded, toggleSidebar }">
        <test-case-sidebar
          :sidebar-expanded="sidebarExpanded"
          :selected-labels="selectedLabels"
          :todo="todo"
          :moved="testCase.moved"
          @test-case-updated="handleTestCaseUpdated"
          @sidebar-toggle="toggleSidebar"
        />
      </template>
    </issuable-show>
  </div>
</template>
