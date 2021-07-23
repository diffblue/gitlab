<script>
import { labelsFilterParam } from 'ee/integrations/jira/issues_show/constants';
import { __, s__ } from '~/locale';
import CopyableField from '~/vue_shared/components/sidebar/copyable_field.vue';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Assignee from './assignee.vue';
import IssueDueDate from './issue_due_date.vue';
import IssueField from './issue_field.vue';

export default {
  name: 'JiraIssuesSidebar',
  components: {
    Assignee,
    IssueDueDate,
    IssueField,
    CopyableField,
    LabelsSelect,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    issueLabelsPath: {
      default: null,
    },
    issuesListPath: {
      default: null,
    },
  },
  props: {
    sidebarExpanded: {
      type: Boolean,
      required: true,
    },
    issue: {
      type: Object,
      required: true,
    },
    isLoadingStatus: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUpdatingLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUpdatingStatus: {
      type: Boolean,
      required: false,
      default: false,
    },
    statuses: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      isEditingLabels: false,
    };
  },
  computed: {
    assignee() {
      // Jira issues have at most 1 assignee
      return (this.issue.assignees || [])[0];
    },
    reference() {
      return this.issue.references?.relative;
    },
    canUpdateLabels() {
      return this.glFeatures.jiraIssueDetailsEditLabels;
    },
    canUpdateStatus() {
      return this.glFeatures.jiraIssueDetailsEditStatus;
    },
  },
  labelsFilterParam,
  i18n: {
    statusTitle: __('Status'),
    statusDropdownEmpty: s__('JiraService|No available statuses'),
    statusDropdownTitle: __('Change status'),
    referenceName: __('Reference'),
  },
  mounted() {
    this.sidebarEl = document.querySelector('aside.right-sidebar');
  },
  methods: {
    toggleSidebar() {
      this.$emit('sidebar-toggle');
    },
    afterSidebarTransitioned(callback) {
      // Wait for sidebar expand animation to complete
      this.sidebarEl.addEventListener('transitionend', callback, { once: true });
    },
    expandSidebarAndOpenDropdown(dropdownRef = null) {
      // Expand the sidebar if not already expanded.
      if (!this.sidebarExpanded) {
        this.toggleSidebar();
      }

      if (dropdownRef) {
        this.afterSidebarTransitioned(() => {
          dropdownRef.expand();
        });
      }
    },
    onIssueLabelsClose() {
      this.isEditingLabels = false;
    },
    onIssueLabelsToggle() {
      this.expandSidebarAndOpenDropdown();
      this.afterSidebarTransitioned(() => {
        this.isEditingLabels = true;
      });
    },
    onIssueLabelsUpdated(labels) {
      this.$emit('issue-labels-updated', labels);
    },
    onIssueStatusFetch() {
      this.$emit('issue-status-fetch');
    },
    onIssueStatusUpdated(status) {
      this.$emit('issue-status-updated', status);
    },
  },
};
</script>

<template>
  <div>
    <assignee class="block" :assignee="assignee" />
    <issue-due-date :due-date="issue.dueDate" />
    <issue-field
      icon="progress"
      :can-update="canUpdateStatus"
      :dropdown-title="$options.i18n.statusDropdownTitle"
      :dropdown-empty="$options.i18n.statusDropdownEmpty"
      :items="statuses"
      :loading="isLoadingStatus"
      :title="$options.i18n.statusTitle"
      :updating="isUpdatingStatus"
      :value="issue.status"
      @expand-sidebar="expandSidebarAndOpenDropdown"
      @issue-field-fetch="onIssueStatusFetch"
      @issue-field-updated="onIssueStatusUpdated"
    />
    <labels-select
      :allow-label-edit="canUpdateLabels"
      :allow-multiselect="true"
      :allow-scoped-labels="true"
      :selected-labels="issue.labels"
      :labels-fetch-path="issueLabelsPath"
      :labels-filter-base-path="issuesListPath"
      :labels-filter-param="$options.labelsFilterParam"
      :labels-select-in-progress="isUpdatingLabels"
      :is-editing="isEditingLabels"
      variant="sidebar"
      class="block labels js-labels-block"
      @onDropdownClose="onIssueLabelsClose"
      @toggleCollapse="onIssueLabelsToggle"
      @updateSelectedLabels="onIssueLabelsUpdated"
    >
      {{ __('None') }}
    </labels-select>
    <copyable-field
      v-if="reference"
      class="block"
      :name="$options.i18n.referenceName"
      :value="reference"
    />
  </div>
</template>
