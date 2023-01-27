<script>
import { GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { formatChartData } from '../utils';
import ColumnChart from './column_chart.vue';

export default {
  name: 'MergeRequestsChart',
  components: {
    ColumnChart,
    GlSprintf,
  },
  inject: [
    'labels',
    'mergeRequestsCreated',
    'totalMergeRequestsClosedCount',
    'totalMergeRequestsCreatedCount',
    'totalMergeRequestsMergedCount',
  ],
  i18n: {
    header: s__('ContributionAnalytics|Merge requests'),
    xAxisTitle: __('User'),
    yAxisTitle: __('Merge Requests created'),
    emptyDescription: s__('ContributionAnalytics|No merge requests for the selected time period.'),
    description: s__(
      'ContributionAnalytics|%{created} created, %{merged} merged, %{closed} closed.',
    ),
  },
  computed: {
    chartData() {
      return formatChartData(this.mergeRequestsCreated.data, this.labels);
    },
    description() {
      if (
        !this.totalMergeRequestsClosedCount &&
        !this.totalMergeRequestsCreatedCount &&
        !this.totalMergeRequestsMergedCount
      ) {
        return this.$options.i18n.emptyDescription;
      }
      return this.$options.i18n.description;
    },
  },
};
</script>
<template>
  <div>
    <div data-qa-selector="merge_request_content">
      <h3>{{ $options.i18n.header }}</h3>
      <gl-sprintf :message="description">
        <template #created>
          <strong>{{ totalMergeRequestsCreatedCount }}</strong>
        </template>
        <template #merged>
          <strong>{{ totalMergeRequestsMergedCount }}</strong>
        </template>
        <template #closed>
          <strong>{{ totalMergeRequestsClosedCount }}</strong>
        </template>
      </gl-sprintf>
    </div>

    <div class="row">
      <div class="col-md-12">
        <column-chart
          :chart-data="chartData"
          :x-axis-title="$options.i18n.xAxisTitle"
          :y-axis-title="$options.i18n.yAxisTitle"
        />
      </div>
    </div>
  </div>
</template>
