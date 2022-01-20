<script>
import { GlPopover, GlBadge } from '@gitlab/ui';
import IssueLink from 'ee/vulnerabilities/components/issue_link.vue';
import { n__ } from '~/locale';

export default {
  components: {
    GlBadge,
    GlPopover,
    IssueLink,
  },
  props: {
    issues: {
      type: Array,
      required: true,
    },
    isJira: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    numberOfIssues() {
      return this.issues.length;
    },
    popoverTitle() {
      return n__('1 Issue', '%d Issues', this.numberOfIssues);
    },
    issueBadgeEl() {
      return () => this.$refs.issueBadge?.$el;
    },
  },
};
</script>

<template>
  <div class="gl-display-inline-block">
    <gl-badge ref="issueBadge" icon="issues" class="gl-px-3">
      {{ numberOfIssues }}
    </gl-badge>
    <gl-popover ref="popover" :target="issueBadgeEl" placement="top">
      <template #title>
        {{ popoverTitle }}
      </template>
      <ul class="gl-list-style-none gl-p-0 gl-m-0">
        <li v-for="{ issue } in issues" :key="issue.iid">
          <issue-link :issue="issue" :is-jira="isJira" />
        </li>
      </ul>
    </gl-popover>
  </div>
</template>
