<script>
import IssueCardTimeInfo from '~/issues/list/components/issue_card_time_info.vue';
import WeightCount from 'ee/issues/components/weight_count.vue';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import { isHealthStatusWidget, isWeightWidget } from '~/work_items/utils';

export default {
  components: {
    IssueCardTimeInfo,
    IssueHealthStatus,
    WeightCount,
  },
  inject: ['hasIssuableHealthStatusFeature'],
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    healthStatus() {
      return (
        this.issue.healthStatus || this.issue.widgets?.find(isHealthStatusWidget)?.healthStatus
      );
    },
    showHealthStatus() {
      return this.hasIssuableHealthStatusFeature && this.healthStatus;
    },
    weight() {
      return this.issue.weight || this.issue.widgets?.find(isWeightWidget)?.weight;
    },
  },
};
</script>

<template>
  <issue-card-time-info :issue="issue">
    <weight-count
      class="issuable-weight gl-mr-3"
      :weight="weight"
      data-qa-selector="issuable_weight_content"
    />
    <issue-health-status v-if="showHealthStatus" :health-status="healthStatus" />
  </issue-card-time-info>
</template>
