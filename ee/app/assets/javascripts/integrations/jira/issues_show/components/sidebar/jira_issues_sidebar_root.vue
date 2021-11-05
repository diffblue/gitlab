<script>
import Assignee from 'ee/external_issues_show/components/sidebar/assignee.vue';
import IssueDueDate from 'ee/external_issues_show/components/sidebar/issue_due_date.vue';
import IssueField from 'ee/external_issues_show/components/sidebar/issue_field.vue';
import { labelsFilterParam } from 'ee/external_issues_show/constants';

import { __, s__ } from '~/locale';
import CopyableField from '~/vue_shared/components/sidebar/copyable_field.vue';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

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
  computed: {
    assignee() {
      // Jira issues have at most 1 assignee
      return (this.issue.assignees || [])[0];
    },
    reference() {
      return this.issue.references?.relative;
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
    avatarSubLabel: __('Jira user'),
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
    <assignee class="block" :assignee="assignee" :avatar-sub-label="$options.i18n.avatarSubLabel" />
    <issue-due-date :due-date="issue.dueDate" />
    <issue-field
      icon="progress"
      :can-edit-field="canUpdateStatus"
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
      :allow-scoped-labels="true"
      :selected-labels="issue.labels"
      :labels-filter-base-path="issuesListPath"
      :labels-filter-param="$options.labelsFilterParam"
      variant="sidebar"
      class="block labels js-labels-block"
      @toggleCollapse="expandSidebarAndOpenDropdown"
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
