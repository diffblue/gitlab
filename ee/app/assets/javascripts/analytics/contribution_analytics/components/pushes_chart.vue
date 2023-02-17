<script>
import { sortBy } from 'lodash';
import { GlSprintf } from '@gitlab/ui';
import { __, s__, formatNumber } from '~/locale';
import ColumnChart from './column_chart.vue';

export default {
  name: 'PushesChart',
  components: {
    ColumnChart,
    GlSprintf,
  },
  i18n: {
    header: __('Pushes'),
    xAxisTitle: __('User'),
    yAxisTitle: __('Pushes'),
    emptyDescription: s__('ContributionAnalytics|No pushes for the selected time period.'),
    description: s__('ContributionAnalytics|%{pushCount} by %{authorCount}.'),
  },
  props: {
    pushes: {
      type: Array,
      required: true,
    },
  },
  computed: {
    pushCount() {
      return this.pushes.reduce((total, { count }) => total + count, 0);
    },
    authorCount() {
      return this.pushes.length;
    },
    sortedPushes() {
      return sortBy(this.pushes, ({ count }) => count).reverse();
    },
    chartData() {
      return this.sortedPushes.map(({ user, count }) => [user, count]);
    },
    description() {
      if (!this.pushCount && !this.authorCount) {
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
    <div data-qa-selector="push_content">
      <h3>{{ $options.i18n.header }}</h3>
      <div data-testid="description">
        <gl-sprintf :message="description">
          <template #pushCount>
            <strong>{{ n__('%d push', '%d pushes', formatNumber(pushCount)) }}</strong>
          </template>
          <template #authorCount>
            <strong>{{
              n__('%d contributor', '%d contributors', formatNumber(authorCount))
            }}</strong>
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
