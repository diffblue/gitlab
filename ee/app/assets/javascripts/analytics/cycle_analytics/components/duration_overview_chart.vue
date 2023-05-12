<script>
import { GlAreaChart, GlChartSeriesLabel } from '@gitlab/ui/dist/charts';
import { mapGetters, mapState } from 'vuex';
import { GlAlert, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import dateFormat from '~/lib/dateformat';
import { buildNullSeries, formatDurationOverviewTooltipMetric } from 'ee/analytics/shared/utils';
import { isNumeric } from '~/lib/utils/number_utils';
import { n__ } from '~/locale';
import {
  DURATION_CHART_Y_AXIS_TITLE,
  DURATION_TOTAL_TIME_DESCRIPTION,
  DURATION_TOTAL_TIME_LABEL,
  DURATION_OVERVIEW_CHART_X_AXIS_DATE_FORMAT,
  DURATION_OVERVIEW_CHART_X_AXIS_TOOLTIP_TITLE_DATE_FORMAT,
  DURATION_OVERVIEW_CHART_NO_DATA,
  DURATION_TOTAL_TIME_NO_DATA,
  DURATION_OVERVIEW_CHART_NO_DATA_LEGEND_ITEM,
} from '../constants';
import {
  DEFAULT_NULL_SERIES_OPTIONS,
  STACKED_AREA_CHART_SERIES_OPTIONS,
  STACKED_AREA_CHART_NULL_SERIES_OPTIONS,
} from '../../shared/constants';

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
      const nonNullSeries = [];
      const nullSeries = [];

      this.durationChartPlottableData.forEach(({ name: seriesName, data: seriesData }) => {
        const valuesSeries = {
          name: seriesName,
          data: seriesData,
        };

        const [nullData, nonNullData] = buildNullSeries({
          seriesData: [valuesSeries],
          nullSeriesTitle: seriesName, // to simultaneously toggle both stage and corresponding null series from legend
          nullSeriesOptions: {
            ...DEFAULT_NULL_SERIES_OPTIONS,
            ...STACKED_AREA_CHART_NULL_SERIES_OPTIONS,
          },
        });

        const { data, name } = nonNullData;

        nonNullSeries.push({ data, name, ...STACKED_AREA_CHART_SERIES_OPTIONS });
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
      const seriesInfo = series.map(({ name, lineStyle }) => ({
        name,
        ...lineStyle,
      }));

      const nonNullSeriesInfo = this.getNonNullSeriesData(seriesInfo);

      return [...nonNullSeriesInfo, DURATION_OVERVIEW_CHART_NO_DATA_LEGEND_ITEM];
    },
  },
  beforeDestroy() {
    if (this.chart) {
      this.chart.off('mouseover', this.onChartDataSeriesMouseOver);
      this.chart.off('mouseout', this.onChartDataSeriesMouseOut);
    }
  },
  methods: {
    getNonNullSeriesData(seriesData) {
      const seriesDataHalf = Math.ceil(seriesData.length / 2);
      /**
       * Since series data is structured as follows: [...nonNullSeries, ...nullSeries]
       * we want to slice the array and return the first half
       */
      return seriesData.slice(0, seriesDataHalf);
    },
    formatTooltipText({ seriesData }) {
      const [dateTime] = seriesData[0].data;
      this.tooltipTitle = dateFormat(
        dateTime,
        DURATION_OVERVIEW_CHART_X_AXIS_TOOLTIP_TITLE_DATE_FORMAT,
      );

      const nonNullSeries = this.getNonNullSeriesData(seriesData);

      this.tooltipContent = nonNullSeries.map(({ seriesName, color, seriesId, data }) => {
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
