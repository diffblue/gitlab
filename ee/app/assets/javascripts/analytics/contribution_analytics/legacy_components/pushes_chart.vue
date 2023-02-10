<script>
import { GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { formatChartData } from '../utils';
import ColumnChart from '../components/column_chart.vue';

export default {
  name: 'PushesChart',
  components: {
    ColumnChart,
    GlSprintf,
  },
  inject: ['labels', 'push', 'totalPushCount', 'totalCommitCount', 'totalPushAuthorCount'],
  i18n: {
    header: __('Pushes'),
    xAxisTitle: __('User'),
    yAxisTitle: __('Pushes'),
    emptyDescription: s__('ContributionAnalytics|No pushes for the selected time period.'),
    description: s__('ContributionAnalytics|%{pushes}, more than %{commits} by %{contributors}.'),
  },
  computed: {
    chartData() {
      return formatChartData(this.push.data, this.labels);
    },
    description() {
      if (!this.totalPushCount && !this.totalCommitCount && !this.totalPushAuthorCount) {
        return this.$options.i18n.emptyDescription;
      }
      return this.$options.i18n.description;
    },
  },
};
</script>
<template>
  <div>
    <div data-qa-selector="push_content">
      <h3>{{ $options.i18n.header }}</h3>
      <gl-sprintf :message="description">
        <template #pushes>
          <strong>{{ n__('%d push', '%d pushes', totalPushCount) }}</strong>
        </template>
        <template #commits>
          <strong>{{ n__('%d commit', '%d commits', totalCommitCount) }}</strong>
        </template>
        <template #contributors>
          <strong>{{ n__('%d contributor', '%d contributors', totalPushAuthorCount) }}</strong>
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
