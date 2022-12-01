<script>
import { componentNames } from 'ee/ci/reports/components/issue_body';
import api from '~/api';
import ReportSection from '~/ci/reports/components/report_section.vue';

export default {
  name: 'GroupedLoadPerformanceReportsApp',
  components: {
    ReportSection,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
    loadingText: {
      type: String,
      required: true,
    },
    errorText: {
      type: String,
      required: true,
    },
    successText: {
      type: String,
      required: true,
    },
    unresolvedIssues: {
      type: Array,
      required: true,
    },
    resolvedIssues: {
      type: Array,
      required: true,
    },
    neutralIssues: {
      type: Array,
      required: true,
    },
    hasIssues: {
      type: Boolean,
      required: true,
    },
  },
  componentNames,
  methods: {
    handleLoadPerformanceToggleEvent() {
      api.trackRedisHllUserEvent(this.$options.expandEvent);
    },
  },
  expandEvent: 'i_testing_load_performance_widget_total',
};
</script>
<template>
  <report-section
    :status="status"
    :loading-text="loadingText"
    :error-text="errorText"
    :success-text="successText"
    :unresolved-issues="unresolvedIssues"
    :resolved-issues="resolvedIssues"
    :neutral-issues="neutralIssues"
    :has-issues="hasIssues"
    :component="$options.componentNames.PerformanceIssueBody"
    should-emit-toggle-event
    class="js-load-performance-widget mr-widget-border-top mr-report"
    @toggleEvent.once="handleLoadPerformanceToggleEvent"
  />
</template>
