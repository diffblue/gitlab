<script>
import { sortBy } from 'lodash';
import { GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
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
    description: s__('ContributionAnalytics|%{pushes} by %{contributors}.'),
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
};
</script>
<template>
  <div>
    <div data-qa-selector="push_content">
      <h3>{{ $options.i18n.header }}</h3>
      <div data-testid="description">
        <gl-sprintf :message="description">
          <template #pushes>
            <strong>{{ n__('%d push', '%d pushes', pushCount) }}</strong>
          </template>
          <template #contributors>
            <strong>{{ n__('%d contributor', '%d contributors', authorCount) }}</strong>
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
