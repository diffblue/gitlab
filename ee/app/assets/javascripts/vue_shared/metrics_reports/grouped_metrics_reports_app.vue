<script>
import { once } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import { componentNames } from 'ee/ci/reports/components/issue_body';
import api from '~/api';
import { n__, s__, sprintf } from '~/locale';
import ReportItem from '~/ci/reports/components/report_item.vue';
import ReportSection from '~/ci/reports/components/report_section.vue';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';
import createStore from './store';

export default {
  name: 'GroupedMetricsReportsApp',
  store: createStore(),
  components: {
    ReportSection,
    ReportItem,
    SmartVirtualList,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  componentNames,
  // Typical height of a report item in px
  typicalReportItemHeight: 32,
  /*
   * The maximum amount of shown issues. This is calculated by
   * ( max-height of report-block-list / typicalReportItemHeight ) + some safety margin
   * We will use VirtualList if we have more items than this number.
   * For entries lower than this number, the virtual scroll list calculates the total height of the element wrongly.
   */
  maxShownReportItems: 20,
  computed: {
    ...mapState(['numberOfChanges', 'isLoading', 'hasError']),
    ...mapGetters(['summaryStatus', 'metrics']),
    groupedSummaryText() {
      if (this.isLoading) {
        return s__('Reports|Metrics reports are loading');
      }

      if (this.hasError) {
        return s__('Reports|Metrics reports failed loading results');
      }

      if (this.numberOfChanges < 1) {
        return s__('Reports|Metrics reports did not change');
      }

      const pointsString = n__('point', 'points', this.numberOfChanges);
      return sprintf(s__('Reports|Metrics reports changed on %{numberOfChanges} %{pointsString}'), {
        numberOfChanges: this.numberOfChanges,
        pointsString,
      });
    },
    hasChanges() {
      return this.numberOfChanges > 0;
    },
    hasMetrics() {
      return this.metrics.length > 0;
    },
    handleToggleEvent() {
      return once(() => {
        api.trackRedisHllUserEvent(this.$options.expandEvent);
      });
    },
  },
  created() {
    this.setEndpoint(this.endpoint);
    this.fetchMetrics();
  },
  methods: {
    ...mapActions(['setEndpoint', 'fetchMetrics']),
  },
  expandEvent: 'i_testing_metrics_report_widget_total',
};
</script>
<template>
  <report-section
    :status="summaryStatus"
    :success-text="groupedSummaryText"
    :loading-text="groupedSummaryText"
    :error-text="groupedSummaryText"
    :has-issues="hasMetrics"
    should-emit-toggle-event
    class="mr-widget-border-top grouped-security-reports mr-report"
    @toggleEvent="handleToggleEvent"
  >
    <template #body>
      <div class="mr-widget-grouped-section report-block">
        <smart-virtual-list
          :length="metrics.length"
          :remain="$options.maxShownReportItems"
          :size="$options.typicalReportItemHeight"
          class="report-block-container"
          wtag="ul"
          wclass="report-block-list"
        >
          <report-item
            v-for="(metric, index) in metrics"
            :key="index"
            :issue="metric"
            status="none"
            :status-icon-size="24"
            :component="$options.componentNames.MetricsReportsIssueBody"
            class="gl-ml-2 gl-mt-2 gl-mb-3"
          />
        </smart-virtual-list>
      </div>
    </template>
  </report-section>
</template>
