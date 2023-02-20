<script>
import {
  GlColumnChart,
  GlLineChart,
  GlStackedColumnChart,
  GlChartLegend,
} from '@gitlab/ui/dist/charts';

import { isNumber } from 'lodash';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import ChartTooltipText from 'ee/analytics/shared/components/chart_tooltip_text.vue';

import { CHART_TYPES, INSIGHTS_DATA_SOURCE_DORA, INSIGHTS_NO_DATA_TOOLTIP } from '../constants';
import InsightsChartError from './insights_chart_error.vue';

const CHART_HEIGHT = 300;

const generateInsightsSeriesInfo = (datasets = []) => {
  if (!datasets.length) return [];
  const [nullSeries, dataSeries] = datasets;
  return [
    {
      type: 'solid',
      name: dataSeries.name,
      // eslint-disable-next-line no-unused-vars
      data: dataSeries.data.map(([_, v]) => v),
      color: dataSeries.itemStyle.color,
    },
    {
      type: 'dashed',
      name: nullSeries.name,
      color: nullSeries.itemStyle.color,
    },
  ];
};

const extractDataSeriesTooltipValue = (seriesData) => {
  const [, dataSeries] = seriesData;
  if (!dataSeries.data) {
    return [];
  }
  const [, dataSeriesValue] = dataSeries.data;
  return isNumber(dataSeriesValue)
    ? [
        {
          title: dataSeries.seriesName,
          value: dataSeriesValue,
        },
      ]
    : [];
};

export default {
  components: {
    GlColumnChart,
    GlLineChart,
    GlStackedColumnChart,
    InsightsChartError,
    ChartSkeletonLoader,
    ChartTooltipText,
    GlChartLegend,
  },
  props: {
    loaded: {
      type: Boolean,
      required: false,
      default: false,
    },
    type: {
      type: String,
      required: false,
      default: null,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    data: {
      type: Object,
      required: false,
      default: null,
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      svgs: {},
      tooltipTitle: null,
      tooltipValue: null,
      chart: null,
    };
  },
  computed: {
    dataZoomConfig() {
      const handleIcon = this.svgs['scroll-handle'];

      return handleIcon ? { handleIcon } : {};
    },
    seriesInfo() {
      return generateInsightsSeriesInfo(this.data.datasets);
    },
    chartOptions() {
      let options = {
        yAxis: {
          minInterval: 1,
        },
      };

      if (this.type === this.$options.chartTypes.LINE) {
        options = {
          ...options,
          xAxis: {
            ...options.xAxis,
            name: this.data.xAxisTitle,
            type: 'category',
          },
          yAxis: {
            ...options.yAxis,
            name: this.data.yAxisTitle,
            type: 'value',
          },
        };
      }

      return { dataZoom: [this.dataZoomConfig], ...options };
    },
    isColumnChart() {
      return [this.$options.chartTypes.BAR, this.$options.chartTypes.PIE].includes(this.type);
    },
    isStackedColumnChart() {
      return this.type === this.$options.chartTypes.STACKED_BAR;
    },
    isLineChart() {
      return this.type === this.$options.chartTypes.LINE;
    },
    isDoraChart() {
      return this.dataSource === INSIGHTS_DATA_SOURCE_DORA;
    },
  },
  methods: {
    setSvg(name) {
      return getSvgIconPathContent(name)
        .then((path) => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch((e) => {
          // eslint-disable-next-line no-console, @gitlab/require-i18n-strings
          console.error('SVG could not be rendered correctly: ', e);
        });
    },
    onChartCreated(chart) {
      this.chart = chart;
      this.setSvg('scroll-handle');
    },
    formatTooltipText(params) {
      const { seriesData } = params;
      const tooltipValue = extractDataSeriesTooltipValue(seriesData);

      this.tooltipTitle = params.value;
      this.tooltipValue = tooltipValue;
    },
  },
  height: CHART_HEIGHT,
  chartTypes: CHART_TYPES,
  i18n: {
    noDataText: INSIGHTS_NO_DATA_TOOLTIP,
  },
};
</script>
<template>
  <div v-if="error" class="insights-chart">
    <insights-chart-error
      :chart-name="title"
      :title="__('This chart could not be displayed')"
      :summary="__('Please check the configuration file for this chart')"
      :error="error"
    />
  </div>
  <div v-else class="insights-chart">
    <h5 class="gl-text-center">{{ title }}</h5>
    <p v-if="description" class="gl-text-center">{{ description }}</p>
    <gl-column-chart
      v-if="loaded && isColumnChart"
      v-bind="$attrs"
      :height="$options.height"
      :bars="data.datasets"
      x-axis-type="category"
      :x-axis-title="data.xAxisTitle"
      :y-axis-title="data.yAxisTitle"
      :option="chartOptions"
      @created="onChartCreated"
    />
    <gl-stacked-column-chart
      v-else-if="loaded && isStackedColumnChart"
      v-bind="$attrs"
      :height="$options.height"
      :bars="data.datasets"
      :group-by="data.labels"
      x-axis-type="category"
      :x-axis-title="data.xAxisTitle"
      :y-axis-title="data.yAxisTitle"
      :option="chartOptions"
      @created="onChartCreated"
    />
    <template v-else-if="loaded && isLineChart">
      <gl-line-chart
        v-bind="$attrs"
        :height="$options.height"
        :data="data.datasets"
        :option="chartOptions"
        :format-tooltip-text="formatTooltipText"
        :show-legend="!isDoraChart"
        @created="onChartCreated"
      >
        <template #tooltip-title> {{ tooltipTitle }} </template>
        <template #tooltip-content>
          <chart-tooltip-text
            :empty-value-text="$options.i18n.noDataText"
            :tooltip-value="tooltipValue"
          />
        </template>
      </gl-line-chart>
      <div v-if="isDoraChart" class="gl-pl-11">
        <gl-chart-legend v-if="chart" :chart="chart" :series-info="seriesInfo" />
      </div>
    </template>
    <chart-skeleton-loader v-else />
  </div>
</template>
