<script>
import Assignee from 'ee/external_issues_show/components/sidebar/assignee.vue';
import IssueDueDate from 'ee/external_issues_show/components/sidebar/issue_due_date.vue';
import IssueField from 'ee/external_issues_show/components/sidebar/issue_field.vue';
import { labelsFilterParam } from 'ee/external_issues_show/constants';

import { __ } from '~/locale';
import CopyableField from '~/sidebar/components/copy/copyable_field.vue';
import LabelsSelect from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';

export default {
  name: 'JiraIssuesSidebar',
  components: {
    Assignee,
    IssueDueDate,
    IssueField,
    CopyableField,
    LabelsSelect,
  },
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
  },
  computed: {
    assignee() {
      // Jira issues have at most 1 assignee
      return (this.issue.assignees || [])[0];
    },
    reference() {
      return this.issue.references?.relative;
    },
  },
  labelsFilterParam,
  i18n: {
    statusTitle: __('Status'),
    referenceName: __('Reference'),
    avatarSubLabel: __('Jira user'),
  },
  methods: {
    expandSidebar() {
      // Expand the sidebar if not already expanded.
      if (!this.sidebarExpanded) {
        this.$emit('sidebar-toggle');
      }
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
      :title="$options.i18n.statusTitle"
      :value="issue.status"
      @expand-sidebar="expandSidebar"
    />
    <labels-select
      :allow-scoped-labels="true"
      :selected-labels="issue.labels"
      :labels-filter-base-path="issuesListPath"
      :labels-filter-param="$options.labelsFilterParam"
      variant="sidebar"
      class="block labels js-labels-block"
      @toggleCollapse="expandSidebar"
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
