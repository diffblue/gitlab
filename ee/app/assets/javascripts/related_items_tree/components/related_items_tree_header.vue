<script>
import { GlAlert, GlPopover, GlIcon, GlButton } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import { __ } from '~/locale';
import { i18n, treeTitle, ParentType } from '../constants';
import EpicHealthStatus from './epic_health_status.vue';
import EpicActionsSplitButton from './epic_issue_actions_split_button.vue';

export default {
  components: {
    GlAlert,
    GlPopover,
    GlIcon,
    GlButton,
    EpicHealthStatus,
    EpicActionsSplitButton,
  },
  data() {
    return {
      isOpen: true,
    };
  },
  computed: {
    ...mapState([
      'parentItem',
      'weightSum',
      'descendantCounts',
      'healthStatus',
      'allowSubEpics',
      'allowIssuableHealthStatus',
    ]),
    totalEpicsCount() {
      return this.descendantCounts.openedEpics + this.descendantCounts.closedEpics;
    },
    totalIssuesCount() {
      return this.descendantCounts.openedIssues + this.descendantCounts.closedIssues;
    },
    totalChildrenCount() {
      return this.totalEpicsCount + this.totalIssuesCount;
    },
    showHealthStatus() {
      return this.healthStatus && this.allowIssuableHealthStatus;
    },
    totalWeight() {
      return this.weightSum.openedIssues + this.weightSum.closedIssues;
    },
    parentIsEpic() {
      return this.parentItem.type === ParentType.Epic;
    },
    toggleIcon() {
      return this.isOpen ? 'chevron-lg-up' : 'chevron-lg-down';
    },
    toggleLabel() {
      return this.isOpen ? __('Collapse') : __('Expand');
    },
  },
  methods: {
    ...mapActions([
      'toggleCreateIssueForm',
      'toggleAddItemForm',
      'toggleCreateEpicForm',
      'setItemInputValue',
    ]),
    showAddIssueForm() {
      this.setItemInputValue('');
      this.toggleAddItemForm({
        issuableType: TYPE_ISSUE,
        toggleState: true,
      });
    },
    showCreateIssueForm() {
      this.toggleCreateIssueForm({
        toggleState: true,
      });
    },
    showAddEpicForm() {
      this.toggleAddItemForm({
        issuableType: TYPE_EPIC,
        toggleState: true,
      });
    },
    showCreateEpicForm() {
      this.toggleCreateEpicForm({
        toggleState: true,
      });
    },
    handleToggle() {
      this.isOpen = !this.isOpen;
      this.$emit('toggleRelatedItemsView', this.isOpen);
    },
  },
  i18n,
  treeTitle,
};
</script>

<template>
  <div
    class="card-header gl-display-flex gl-pl-5 gl-pr-4 gl-py-4 gl-flex-direction-column gl-sm-flex-direction-row gl-bg-white"
  >
    <div
      class="gl-display-flex gl-flex-grow-1 gl-flex-shrink-0 gl-flex-wrap gl-flex-direction-column gl-sm-flex-direction-row"
    >
      <div class="gl-display-flex gl-flex-shrink-0 gl-align-items-center gl-flex-wrap">
        <h3 class="card-title h5 gl-my-0 gl-flex-shrink-0">
          {{ allowSubEpics ? __('Child issues and epics') : $options.treeTitle[parentItem.type] }}
        </h3>
        <div
          v-if="parentIsEpic"
          class="gl-display-inline-flex lh-100 gl-vertical-align-middle gl-ml-3 gl-flex-wrap"
        >
          <gl-popover :target="() => $refs.countBadge">
            <p v-if="allowSubEpics" class="gl-font-weight-bold gl-m-0">
              {{ __('Epics') }} &#8226;
              <span class="gl-font-weight-normal"
                >{{
                  sprintf(__('%{openedEpics} open, %{closedEpics} closed'), {
                    openedEpics: descendantCounts.openedEpics,
                    closedEpics: descendantCounts.closedEpics,
                  })
                }}
              </span>
            </p>
            <p class="gl-font-weight-bold gl-m-0">
              {{ __('Issues') }} &#8226;
              <span class="gl-font-weight-normal"
                >{{
                  sprintf(__('%{openedIssues} open, %{closedIssues} closed'), {
                    openedIssues: descendantCounts.openedIssues,
                    closedIssues: descendantCounts.closedIssues,
                  })
                }}
              </span>
            </p>
            <p class="gl-font-weight-bold gl-m-0">
              {{ __('Total weight') }} &#8226;
              <span class="gl-font-weight-normal">{{ totalWeight }} </span>
            </p>
            <gl-alert
              v-if="totalChildrenCount > 0"
              :dismissible="false"
              class="gl-max-w-26 gl-mt-3"
            >
              {{ $options.i18n.permissionAlert }}
            </gl-alert>
          </gl-popover>
          <div
            ref="countBadge"
            class="issue-count-badge gl-display-inline-flex gl-text-gray-500 gl-p-0 gl-pr-5"
          >
            <span
              v-if="allowSubEpics"
              class="gl-display-inline-flex gl-align-items-center gl-font-weight-bold"
            >
              <gl-icon name="epic" class="gl-mr-2" />
              {{ totalEpicsCount }}
            </span>
            <span
              class="gl-display-inline-flex gl-align-items-center gl-font-weight-bold"
              :class="{ 'gl-ml-3': allowSubEpics }"
            >
              <gl-icon name="issues" class="gl-mr-2" />
              {{ totalIssuesCount }}
            </span>
            <span
              class="gl-display-inline-flex gl-align-items-center gl-font-weight-bold"
              :class="{ 'gl-ml-3': allowSubEpics }"
            >
              <gl-icon name="weight" class="gl-mr-2" />
              {{ totalWeight }}
            </span>
          </div>
        </div>
      </div>
      <div
        class="gl-display-flex gl-sm-display-inline-flex lh-100 gl-vertical-align-middle gl-sm-ml-2 gl-ml-0 gl-flex-wrap gl-mt-2 gl-sm-mt-0"
      >
        <epic-health-status v-if="showHealthStatus" :health-status="healthStatus" />
      </div>
    </div>

    <div
      v-if="parentIsEpic"
      class="gl-display-flex gl-sm-display-inline-flex gl-sm-ml-auto lh-100 gl-vertical-align-middle gl-mt-3 gl-sm-mt-0 gl-pl-0 gl-sm-pl-7"
    >
      <div
        class="gl-flex-grow-1 gl-flex-direction-column gl-sm-flex-direction-row js-button-container"
      >
        <epic-actions-split-button
          :allow-sub-epics="allowSubEpics"
          class="js-add-epics-issues-button w-100"
          @showAddIssueForm="showAddIssueForm"
          @showCreateIssueForm="showCreateIssueForm"
          @showAddEpicForm="showAddEpicForm"
          @showCreateEpicForm="showCreateEpicForm"
        />
      </div>
      <div class="gl-pl-3 gl-ml-3 gl-border-l-1 gl-border-l-solid gl-border-l-gray-100">
        <gl-button
          category="tertiary"
          size="small"
          :icon="toggleIcon"
          :aria-label="toggleLabel"
          data-testid="toggle-links"
          @click="handleToggle"
        />
      </div>
    </div>
  </div>
</template>
