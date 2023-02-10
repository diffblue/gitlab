<script>
import { GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { formatChartData } from '../utils';
import ColumnChart from '../components/column_chart.vue';

export default {
  name: 'IssuesChart',
  components: {
    ColumnChart,
    GlSprintf,
  },
  inject: ['labels', 'issuesClosed', 'totalIssuesCreatedCount', 'totalIssuesClosedCount'],
  i18n: {
    header: s__('ContributionAnalytics|Issues'),
    xAxisTitle: __('User'),
    yAxisTitle: __('Issues closed'),
    emptyDescription: s__('ContributionAnalytics|No issues for the selected time period.'),
    description: s__('ContributionAnalytics|%{created} created, %{closed} closed.'),
  },
  computed: {
    chartData() {
      return formatChartData(this.issuesClosed.data, this.labels);
    },
    description() {
      if (this.totalIssuesClosedCount === 0 && this.totalIssuesCreatedCount === 0) {
        return this.$options.i18n.emptyDescription;
      }
      return this.$options.i18n.description;
    },
  },
};
</script>
<template>
  <div>
    <div data-qa-selector="issue_content">
      <h3>{{ $options.i18n.header }}</h3>
      <gl-sprintf :message="description">
        <template #created>
          <strong>{{ totalIssuesCreatedCount }}</strong>
        </template>
        <template #closed>
          <strong>{{ totalIssuesClosedCount }}</strong>
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
