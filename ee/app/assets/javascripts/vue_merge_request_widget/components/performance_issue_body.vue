<script>
/**
 * Renders Perfomance issue body text
 *  [name] :[score] [symbol] [delta] in [link]
 */
import { formattedChangeInPercent } from '~/lib/utils/number_utils';
import ReportLink from '~/ci/reports/components/report_link.vue';

function formatScore(value) {
  if (Number(value) && !Number.isInteger(value)) {
    return (Math.floor(parseFloat(value) * 100) / 100).toFixed(2);
  }
  return value;
}

export default {
  name: 'PerformanceIssueBody',

  components: {
    ReportLink,
  },

  props: {
    issue: {
      type: Object,
      required: true,
    },
  },

  computed: {
    issueScore() {
      return this.issue.score ? formatScore(this.issue.score) : false;
    },
    issueDelta() {
      if (!this.issue.delta) {
        return false;
      }
      return this.issue.delta >= 0
        ? `+${formatScore(this.issue.delta)}`
        : formatScore(this.issue.delta);
    },
    issueDeltaPercentage() {
      if (!this.issue.delta || !this.issue.score || !Number(this.issue.score)) {
        return false;
      }
      const oldScore = parseFloat(this.issue.score) - this.issue.delta;
      return formattedChangeInPercent(oldScore, this.issue.score);
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description gl-mt-2 gl-mb-2">
    <div class="report-block-list-issue-description-text">
      <template v-if="issueScore">
        {{ issue.name }}: <strong>{{ issueScore }}</strong>
      </template>
      <template v-else>
        {{ issue.name }}
      </template>
      <template v-if="issueDelta"> ({{ issueDelta }}) </template>
      <template v-if="issueDeltaPercentage"> ({{ issueDeltaPercentage }}) </template>
    </div>

    <report-link v-if="issue.path" :issue="issue" />
  </div>
</template>
