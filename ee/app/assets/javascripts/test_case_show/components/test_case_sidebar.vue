<script>
import { GlTooltipDirective as GlTooltip, GlButton, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import Mousetrap from 'mousetrap';

import { keysFor, ISSUABLE_CHANGE_LABEL } from '~/behaviors/shortcuts/keybindings';
import { s__, __ } from '~/locale';
import ProjectSelect from '~/vue_shared/components/sidebar/issuable_move_dropdown.vue';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

import TestCaseGraphQL from '../mixins/test_case_graphql';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
    LabelsSelect,
    ProjectSelect,
  },
  directives: {
    GlTooltip,
  },
  mixins: [TestCaseGraphQL],
  inject: [
    'projectFullPath',
    'testCaseId',
    'canEditTestCase',
    'canMoveTestCase',
    'labelsFetchPath',
    'labelsManagePath',
    'projectsFetchPath',
  ],
  props: {
    sidebarExpanded: {
      type: Boolean,
      required: true,
    },
    todo: {
      type: Object,
      required: false,
      default: null,
    },
    selectedLabels: {
      type: Array,
      required: true,
    },
    moved: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      sidebarExpandedOnClick: false,
      testCaseLabelsSelectInProgress: false,
    };
  },
  computed: {
    isTodoPending() {
      return this.todo?.state === 'pending';
    },
    todoUpdateInProgress() {
      return this.$apollo.queries.testCase.loading || this.testCaseTodoUpdateInProgress;
    },
    todoActionText() {
      return this.isTodoPending ? __('Mark as done') : __('Add a to do');
    },
    todoIcon() {
      return this.isTodoPending ? 'todo-done' : 'todo-add';
    },
    selectProjectDropdownButtonTitle() {
      return this.testCaseMoveInProgress
        ? s__('TestCases|Moving test case')
        : s__('TestCases|Move test case');
    },
  },
  mounted() {
    this.sidebarEl = document.querySelector('aside.right-sidebar');
    Mousetrap.bind(keysFor(ISSUABLE_CHANGE_LABEL), this.handleLabelsCollapsedButtonClick);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(ISSUABLE_CHANGE_LABEL));
  },
  methods: {
    handleTodoButtonClick() {
      if (this.isTodoPending) {
        this.markTestCaseTodoDone();
      } else {
        this.addTestCaseAsTodo();
      }
    },
    toggleSidebar() {
      this.$emit('sidebar-toggle');
    },
    expandSidebarAndOpenDropdown(dropdownButtonSelector) {
      // Expand the sidebar if not already expanded.
      if (!this.sidebarExpanded) {
        this.toggleSidebar();
        this.sidebarExpandedOnClick = true;
      }

      this.$nextTick(() => {
        // Wait for sidebar expand animation to complete
        // before revealing the dropdown.
        this.sidebarEl.addEventListener(
          'transitionend',
          () => {
            document
              .querySelector(dropdownButtonSelector)
              .dispatchEvent(new Event('click', { bubbles: true, cancelable: false }));
          },
          { once: true },
        );
      });
    },
    handleSidebarDropdownClose() {
      if (this.sidebarExpandedOnClick) {
        this.sidebarExpandedOnClick = false;
        this.toggleSidebar();
      }
    },
    handleLabelsCollapsedButtonClick() {
      this.expandSidebarAndOpenDropdown('.js-labels-block .js-sidebar-dropdown-toggle');
    },
    handleProjectsCollapsedButtonClick() {
      this.expandSidebarAndOpenDropdown('.js-issuable-move-block .js-sidebar-dropdown-toggle');
    },
    handleUpdateSelectedLabels(labels) {
      // Iterate over selection and check if labels which were
      // either selected or removed aren't leading to same selection
      // as current one, as then we don't want to make network call
      // since nothing has changed.
      const anyLabelUpdated = labels.some((label) => {
        // Find this label in existing selection.
        const existingLabel = this.selectedLabels.find((l) => l.id === label.id);

        // Check either of the two following conditions;
        // 1. A label that's not currently applied is being applied.
        // 2. A label that's already applied is being removed.
        return (!existingLabel && label.set) || (existingLabel && !label.set);
      });

      // Only proceed with action if there are any label updates to be done.
      if (anyLabelUpdated) {
        this.testCaseLabelsSelectInProgress = true;

        return this.updateTestCase({
          variables: {
            addLabelIds: labels.filter((label) => label.set).map((label) => label.id),
            removeLabelIds: labels.filter((label) => !label.set).map((label) => label.id),
          },
          errorMessage: s__('TestCases|Something went wrong while updating the test case labels.'),
        })
          .then((updatedTestCase) => {
            this.$emit('test-case-updated', updatedTestCase);
          })
          .finally(() => {
            this.testCaseLabelsSelectInProgress = false;
          });
      }
      return null;
    },
  },
};
</script>

<template>
  <div class="test-case-sidebar-items">
    <template v-if="canEditTestCase">
      <div v-if="sidebarExpanded" data-testid="todo" class="block todo gl-display-flex">
        <span class="gl-flex-grow-1">{{ __('To Do') }}</span>
        <gl-button :loading="todoUpdateInProgress" size="small" @click="handleTodoButtonClick">{{
          todoActionText
        }}</gl-button>
      </div>
      <div v-else class="block todo">
        <gl-button
          v-gl-tooltip:body.viewport.left
          :title="todoActionText"
          class="sidebar-collapsed-icon"
          category="tertiary"
          @click="handleTodoButtonClick"
        >
          <gl-loading-icon v-if="todoUpdateInProgress" size="sm" />
          <gl-icon v-else :name="todoIcon" :class="{ 'todo-undone': isTodoPending }" />
        </gl-button>
      </div>
    </template>
    <labels-select
      :allow-label-edit="canEditTestCase"
      :allow-label-create="true"
      :allow-multiselect="true"
      :allow-scoped-labels="true"
      :selected-labels="selectedLabels"
      :labels-select-in-progress="testCaseLabelsSelectInProgress"
      :labels-fetch-path="labelsFetchPath"
      :labels-manage-path="labelsManagePath"
      variant="sidebar"
      class="block labels js-labels-block"
      @updateSelectedLabels="handleUpdateSelectedLabels"
      @onDropdownClose="handleSidebarDropdownClose"
      @toggleCollapse="handleLabelsCollapsedButtonClick"
      >{{ __('None') }}</labels-select
    >
    <project-select
      v-if="canMoveTestCase && !moved"
      :projects-fetch-path="projectsFetchPath"
      :dropdown-button-title="selectProjectDropdownButtonTitle"
      :dropdown-header-title="__('Move test case')"
      :move-in-progress="testCaseMoveInProgress"
      class="block"
      @dropdown-close="handleSidebarDropdownClose"
      @toggle-collapse="handleProjectsCollapsedButtonClick"
      @move-issuable="moveTestCase"
    />
  </div>
</template>
