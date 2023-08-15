<script>
import { GlEmptyState } from '@gitlab/ui';
import { isUndefined } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';

import { __ } from '~/locale';
import InsightsChart from './insights_chart.vue';

export default {
  components: {
    GlEmptyState,
    InsightsChart,
  },
  props: {
    queryEndpoint: {
      type: String,
      required: true,
    },
    pageConfig: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState('insights', ['chartData']),
    emptyState() {
      return {
        title: __('There are no charts configured for this page'),
        description: __(
          'Please check the configuration file to ensure that a collection of charts has been declared.',
        ),
      };
    },
    charts() {
      return this.pageConfig.charts;
    },
    chartKeys() {
      return this.charts.map((chart) => chart.title);
    },
    hasChartsConfigured() {
      return !isUndefined(this.charts) && this.charts.length > 0;
    },
  },
  watch: {
    pageConfig() {
      this.fetchCharts();
    },
  },
  mounted() {
    this.fetchCharts();
  },
  methods: {
    ...mapActions('insights', ['fetchChartData', 'initChartData']),
    fetchCharts() {
      if (this.hasChartsConfigured) {
        this.initChartData(this.chartKeys);

        this.charts.forEach((chart) =>
          this.fetchChartData({ endpoint: this.queryEndpoint, chart }),
        );
      }
    },
  },
};
</script>
<template>
  <div class="insights-page" data-qa-selector="insights_page">
    <div v-if="hasChartsConfigured" class="js-insights-page-container">
      <h4 class="text-center">{{ pageConfig.title }}</h4>
      <div class="insights-charts" data-qa-selector="insights_charts">
        <insights-chart
          v-for="({ loaded, type, description, data, error }, key, index) in chartData"
          :key="index"
          :loaded="loaded"
          :type="type"
          :title="key"
          :description="description"
          :data="data"
          :error="error"
        />
      </div>
    </div>
    <gl-empty-state
      v-else
      :title="emptyState.title"
      :description="emptyState.description"
      svg-path="/assets/illustrations/monitoring/getting_started.svg"
    />
  </div>
</template>
