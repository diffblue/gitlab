<script>
import { sortBy } from 'lodash';
import { GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ColumnChart from './column_chart.vue';

export default {
  name: 'IssuesChart',
  components: {
    ColumnChart,
    GlSprintf,
  },
  i18n: {
    header: s__('ContributionAnalytics|Issues'),
    xAxisTitle: __('User'),
    yAxisTitle: __('Issues closed'),
    emptyDescription: s__('ContributionAnalytics|No issues for the selected time period.'),
    description: s__('ContributionAnalytics|%{created} created, %{closed} closed.'),
  },
  props: {
    issues: {
      type: Array,
      required: true,
    },
  },
  computed: {
    createdCount() {
      return this.issues.reduce((total, { created }) => total + created, 0);
    },
    closedCount() {
      return this.issues.reduce((total, { closed }) => total + closed, 0);
    },
    sortedIssues() {
      return sortBy(this.issues, ({ closed }) => closed).reverse();
    },
    chartData() {
      return this.sortedIssues.map(({ user, closed }) => [user, closed]);
    },
    description() {
      if (this.closedCount === 0 && this.createdCount === 0) {
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
      <div data-testid="description">
        <gl-sprintf :message="description">
          <template #created>
            <strong>{{ createdCount }}</strong>
          </template>
          <template #closed>
            <strong>{{ closedCount }}</strong>
          </template>
        </gl-sprintf>
      </div>
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
