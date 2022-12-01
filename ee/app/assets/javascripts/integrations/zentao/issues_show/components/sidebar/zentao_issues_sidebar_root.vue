<script>
import Assignee from 'ee/external_issues_show/components/sidebar/assignee.vue';
import IssueDueDate from 'ee/external_issues_show/components/sidebar/issue_due_date.vue';
import IssueField from 'ee/external_issues_show/components/sidebar/issue_field.vue';
import { s__, __ } from '~/locale';
import LabelsSelect from '~/sidebar/components/labels/labels_select_vue/labels_select_root.vue';

export default {
  name: 'ZentaoIssuesSidebar',
  components: {
    Assignee,
    IssueDueDate,
    IssueField,
    LabelsSelect,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    assignee() {
      // Zentao issues have at most 1 assignee
      return (this.issue.assignees || [])[0];
    },
    reference() {
      return this.issue.references?.relative;
    },
  },
  i18n: {
    statusTitle: __('Status'),
    referenceName: __('Reference'),
    avatarSubLabel: s__('ZenTaoIntegration|ZenTao user'),
  },
};
</script>

<template>
  <div>
    <assignee class="block" :assignee="assignee" :avatar-sub-label="$options.i18n.avatarSubLabel" />
    <issue-due-date :due-date="issue.dueDate" />
    <issue-field icon="progress" :title="$options.i18n.statusTitle" :value="issue.status" />
    <labels-select
      :allow-scoped-labels="true"
      :selected-labels="issue.labels"
      variant="sidebar"
      class="block labels"
    >
      {{ __('None') }}
    </labels-select>
  </div>
</template>
