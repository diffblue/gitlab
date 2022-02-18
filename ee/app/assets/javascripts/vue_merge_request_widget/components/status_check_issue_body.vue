<script>
import SummaryRow from '~/reports/components/summary_row.vue';
import { ICON_SUCCESS, ICON_PENDING, ICON_FAILED } from '~/reports/constants';
import { PASSED, APPROVED, FAILED } from '../../reports/status_checks_report/constants';

export default {
  name: 'StatusCheckIssueBody',
  components: {
    SummaryRow,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
  },
  computed: {
    statusIcon() {
      switch (this.issue.status) {
        case APPROVED:
          return ICON_SUCCESS;
        case PASSED:
          return ICON_SUCCESS;
        case FAILED:
          return ICON_FAILED;
        default:
          return ICON_PENDING;
      }
    },
  },
};
</script>

<template>
  <div class="gl-w-full" :data-testid="`mr-status-check-issue-${issue.id}`">
    <summary-row :status-icon="statusIcon" nested-summary>
      <template #summary>
        <span>{{ issue.name }}: {{ issue.external_url }}</span>
      </template>
    </summary-row>
  </div>
</template>
