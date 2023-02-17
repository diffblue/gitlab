<script>
import { sortBy } from 'lodash';
import { GlSprintf } from '@gitlab/ui';
import { __, s__, formatNumber } from '~/locale';
import ColumnChart from './column_chart.vue';

export default {
  name: 'MergeRequestsChart',
  components: {
    ColumnChart,
    GlSprintf,
  },
  i18n: {
    header: s__('ContributionAnalytics|Merge requests'),
    xAxisTitle: __('User'),
    yAxisTitle: __('Merge Requests created'),
    emptyDescription: s__('ContributionAnalytics|No merge requests for the selected time period.'),
    description: s__(
      'ContributionAnalytics|%{createdCount} created, %{mergedCount} merged, %{closedCount} closed.',
    ),
  },
  props: {
    mergeRequests: {
      type: Array,
      required: true,
    },
  },
  computed: {
    createdCount() {
      return this.mergeRequests.reduce((total, { created }) => total + created, 0);
    },
    mergedCount() {
      return this.mergeRequests.reduce((total, { merged }) => total + merged, 0);
    },
    closedCount() {
      return this.mergeRequests.reduce((total, { closed }) => total + closed, 0);
    },
    sortedMergeRequests() {
      return sortBy(this.mergeRequests, ({ created }) => created).reverse();
    },
    chartData() {
      return this.sortedMergeRequests.map(({ user, created }) => [user, created]);
    },
    description() {
      if (!this.mergeRequests.length) {
        return this.$options.i18n.emptyDescription;
      }
      return this.$options.i18n.description;
    },
  },
  methods: {
    formatNumber(number) {
      return formatNumber(number);
    },
  },
};
</script>
<template>
  <div>
    <div data-qa-selector="merge_request_content">
      <h3>{{ $options.i18n.header }}</h3>
      <div data-testid="description">
        <gl-sprintf :message="description">
          <template #createdCount>
            <strong>{{ formatNumber(createdCount) }}</strong>
          </template>
          <template #mergedCount>
            <strong>{{ formatNumber(mergedCount) }}</strong>
          </template>
          <template #closedCount>
            <strong>{{ formatNumber(closedCount) }}</strong>
          </template>
        </gl-sprintf>
      </div>
    </div>

    <column-chart
      class="gl-w-full"
      :chart-data="chartData"
      :x-axis-title="$options.i18n.xAxisTitle"
      :y-axis-title="$options.i18n.yAxisTitle"
    />
  </div>
</template>
