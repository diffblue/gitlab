<script>
import { GlAreaChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import { mapGetters, mapState } from 'vuex';
import { GlAlert, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import dateFormat from '~/lib/dateformat';
import { buildNullSeries, formatDurationOverviewTooltipMetric } from 'ee/analytics/shared/utils';
import { isNumeric } from '~/lib/utils/number_utils';
import { n__ } from '~/locale';
import { progressiveSummation } from '../utils';
import {
  DURATION_CHART_Y_AXIS_TITLE,
  DURATION_TOTAL_TIME_DESCRIPTION,
  DURATION_TOTAL_TIME_LABEL,
  DURATION_OVERVIEW_CHART_X_AXIS_DATE_FORMAT,
  DURATION_OVERVIEW_CHART_X_AXIS_TOOLTIP_TITLE_DATE_FORMAT,
  DURATION_OVERVIEW_CHART_NO_DATA,
  DURATION_TOTAL_TIME_NO_DATA,
} from '../constants';

export default {
  name: 'DurationOverviewChart',
  components: {
    GlAreaChart,
    GlChartSeriesLabel,
    GlIcon,
    GlAlert,
    ChartSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      chart: null,
      tooltipTitle: '',
      tooltipContent: [],
      activeDataSeries: '',
    };
  },
  computed: {
    ...mapState('durationChart', ['isLoading', 'errorMessage']),
    ...mapGetters('durationChart', ['durationChartPlottableData']),
    hasData() {
      return Boolean(
        !this.isLoading &&
          this.durationChartPlottableData.some(({ data }) =>
            data.some(([, metric]) => metric !== null),
          ),
      );
    },
    error() {
      return this.errorMessage || DURATION_TOTAL_TIME_NO_DATA;
    },
    chartData() {
      const summedData = progressiveSummation(this.durationChartPlottableData);

      const nonNullSeries = [];
      const nullSeries = [];

      summedData.forEach(({ name: seriesName, data: seriesData }) => {
        const valuesSeries = {
          name: seriesName,
          data: seriesData,
        };

        const [nullData, nonNullData] = buildNullSeries({
          seriesData: [valuesSeries],
          nullSeriesTitle: DURATION_OVERVIEW_CHART_NO_DATA,
        });

        const { data, name } = nonNullData;

        nonNullSeries.push({ data, name });
        nullSeries.push(nullData);
      });

      return [...nonNullSeries, ...nullSeries];
    },
    chartOptions() {
      return {
        xAxis: {
          name: '',
          type: 'time',
          axisLabel: {
            formatter: (date) => dateFormat(date, DURATION_OVERVIEW_CHART_X_AXIS_DATE_FORMAT),
          },
        },
        yAxis: {
          name: this.$options.i18n.yAxisTitle,
          type: 'value',
          axisLabel: {
            formatter: (value) => value,
          },
        },
      };
    },
    compiledChartOptions() {
      return this.chart ? this.chart.getOption() : null;
    },
    legendSeriesInfo() {
      if (!this.compiledChartOptions) return [];

      const { series } = this.compiledChartOptions;
      const seriesInfo = series.map(({ name, lineStyle: { color, type } }) => ({
        name,
        color,
        type,
      }));

      const nonNullSeriesInfo = seriesInfo.filter(({ name }) => this.isNonNullSeriesData(name));
      const [nullSeriesItem] = seriesInfo.filter(({ name }) => !this.isNonNullSeriesData(name));

      return [...nonNullSeriesInfo, nullSeriesItem];
    },
  },
  beforeDestroy() {
    if (this.chart) {
      this.chart.off('mouseover', this.onChartDataSeriesMouseOver);
      this.chart.off('mouseout', this.onChartDataSeriesMouseOut);
    }
  },
  methods: {
    isNonNullSeriesData(seriesName) {
      return seriesName !== DURATION_OVERVIEW_CHART_NO_DATA;
    },
    formatTooltipText({ seriesData }) {
      const [dateTime] = seriesData[0].data;
      this.tooltipTitle = dateFormat(
        dateTime,
        DURATION_OVERVIEW_CHART_X_AXIS_TOOLTIP_TITLE_DATE_FORMAT,
      );

      const nonNullSeries = seriesData.filter(({ seriesName }) =>
        this.isNonNullSeriesData(seriesName),
      );

      this.tooltipContent = nonNullSeries.map(({ seriesName, color, seriesId, dataIndex }, idx) => {
        const data = this.durationChartPlottableData[idx].data[dataIndex];
        const [, metric] = data;

        return {
          seriesId,
          label: seriesName,
          value: isNumeric(metric)
            ? n__('%d day', '%d days', formatDurationOverviewTooltipMetric(metric))
            : this.$options.i18n.noData,
          color,
        };
      });
    },
    onChartCreated(chart) {
      this.chart = chart;

      this.chart.on('mouseover', 'series', this.onChartDataSeriesMouseOver);
      this.chart.on('mouseout', 'series', this.onChartDataSeriesMouseOut);
    },
    onChartDataSeriesMouseOver({ seriesId }) {
      this.activeDataSeries = seriesId;
    },
    onChartDataSeriesMouseOut() {
      this.activeDataSeries = null;
    },
  },
  i18n: {
    title: DURATION_TOTAL_TIME_LABEL,
    tooltipText: DURATION_TOTAL_TIME_DESCRIPTION,
    yAxisTitle: DURATION_CHART_Y_AXIS_TITLE,
    noData: DURATION_OVERVIEW_CHART_NO_DATA,
  },
};
</script>

<template>
  <chart-skeleton-loader v-if="isLoading" size="md" class="gl-my-4 gl-py-4" />
  <div
    v-else
    class="gl-display-flex gl-flex-direction-column"
    data-testid="vsa-duration-overview-chart"
  >
    <h4 class="gl-mt-0">
      {{ $options.i18n.title }}&nbsp;<gl-icon
        v-gl-tooltip.hover
        name="information-o"
        :title="$options.i18n.tooltipText"
      />
    </h4>
    <gl-area-chart
      v-if="hasData"
      :option="chartOptions"
      :data="chartData"
      :include-legend-avg-max="false"
      :format-tooltip-text="formatTooltipText"
      :legend-series-info="legendSeriesInfo"
      @created="onChartCreated"
    >
      <template #tooltip-title>
        <div>{{ tooltipTitle }}</div>
      </template>

      <template #tooltip-content>
        <div
          v-for="metric in tooltipContent"
          :key="metric.seriesId"
          class="gl-display-flex gl-justify-content-space-between gl-line-height-24 gl-min-w-20"
          :class="{ 'gl-font-weight-bold': activeDataSeries === metric.seriesId }"
        >
          <gl-chart-series-label class="gl-mr-7" :color="metric.color">
            {{ metric.label }}
          </gl-chart-series-label>
          <div>{{ metric.value }}</div>
        </div>
      </template>
    </gl-area-chart>
    <gl-alert v-else variant="info" :dismissible="false" class="gl-mt-3">
      {{ error }}
    </gl-alert>
  </div>
</template>
