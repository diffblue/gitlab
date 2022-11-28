<script>
import IssueCardStatistics from '~/issues/list/components/issue_card_statistics.vue';
import BlockingIssuesCount from '../../components/blocking_issues_count.vue';

export default {
  components: {
    BlockingIssuesCount,
    IssueCardStatistics,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <issue-card-statistics :issue="issue">
    <blocking-issues-count
      class="gl-display-none gl-sm-display-block gl-mr-3"
      :blocking-issues-count="issue.blockingCount"
      is-list-item
      data-testid="blocking-issues"
    />
  </issue-card-statistics>
</template>
