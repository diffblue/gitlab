<script>
import { mapState, mapGetters } from 'vuex';
import { dataVizBlue500 } from '@gitlab/ui/scss_to_js/scss_variables';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { GlAlert, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { sprintf } from '~/locale';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import {
  DURATION_STAGE_TIME_DESCRIPTION,
  DURATION_STAGE_TIME_NO_DATA,
  DURATION_STAGE_TIME_LABEL,
  DURATION_TOTAL_TIME_DESCRIPTION,
  DURATION_TOTAL_TIME_NO_DATA,
  DURATION_TOTAL_TIME_LABEL,
  DURATION_CHART_X_AXIS_TITLE,
  DURATION_CHART_Y_AXIS_TITLE,
} from '../constants';

const formatTooltipDate = (date) => dateFormat(date, dateFormats.defaultDate);

export default {
  name: 'DurationChart',
  components: {
    GlAlert,
    GlIcon,
    GlLineChart,
    ChartSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
  },
  data() {
    return { tooltipTitle: '', tooltipContent: '' };
  },
  computed: {
    ...mapState(['selectedStage']),
    ...mapState('durationChart', ['isLoading', 'errorMessage']),
    ...mapGetters(['isOverviewStageSelected']),
    ...mapGetters('durationChart', ['durationChartPlottableData']),
    hasData() {
      return Boolean(!this.isLoading && this.durationChartPlottableData.length);
    },
    error() {
      if (this.errorMessage) {
        return this.errorMessage;
      }
      return this.isOverviewStageSelected
        ? DURATION_TOTAL_TIME_NO_DATA
        : DURATION_STAGE_TIME_NO_DATA;
    },
    title() {
      return this.isOverviewStageSelected
        ? DURATION_TOTAL_TIME_LABEL
        : sprintf(DURATION_STAGE_TIME_LABEL, {
            title: capitalizeFirstCharacter(this.selectedStage.title),
          });
    },
    tooltipText() {
      return this.isOverviewStageSelected
        ? DURATION_TOTAL_TIME_DESCRIPTION
        : DURATION_STAGE_TIME_DESCRIPTION;
    },
    chartData() {
      return [
        {
          name: this.$options.i18n.yAxisTitle,
          data: this.durationChartPlottableData,
          lineStyle: {
            color: dataVizBlue500,
          },
        },
      ];
    },
    chartOptions() {
      return {
        xAxis: {
          name: this.$options.i18n.xAxisTitle,
          type: 'time',
          axisLabel: {
            formatter: formatTooltipDate,
          },
        },
        yAxis: {
          name: this.$options.i18n.yAxisTitle,
          type: 'value',
          axisLabel: {
            formatter: (value) => value,
          },
        },
        dataZoom: [
          {
            type: 'slider',
            bottom: 10,
            start: 0,
          },
        ],
      };
    },
  },
  methods: {
    renderTooltip({ seriesData }) {
      const [dateTime, metric] = seriesData[0].data;
      this.tooltipTitle = formatTooltipDate(dateTime);
      this.tooltipContent = metric;
    },
  },
  durationChartTooltipDateFormat: dateFormats.defaultDate,
  i18n: {
    xAxisTitle: DURATION_CHART_X_AXIS_TITLE,
    yAxisTitle: DURATION_CHART_Y_AXIS_TITLE,
  },
};
</script>
<template>
  <chart-skeleton-loader v-if="isLoading" size="md" class="gl-my-4 gl-py-4" />
  <div v-else class="gl-display-flex gl-flex-direction-column" data-testid="vsa-duration-chart">
    <h4 class="gl-mt-0">
      {{ title }}&nbsp;<gl-icon v-gl-tooltip.hover name="information-o" :title="tooltipText" />
    </h4>
    <gl-line-chart
      v-if="hasData"
      :option="chartOptions"
      :data="chartData"
      :show-toolbox="false"
      :format-tooltip-text="renderTooltip"
      :include-legend-avg-max="false"
      :show-legend="false"
    >
      <template #tooltip-title>
        <div>{{ tooltipTitle }} ({{ $options.i18n.xAxisTitle }})</div>
      </template>
      <template #tooltip-content>
        <p class="gl-m-0">
          {{ $options.i18n.yAxisTitle }}:
          <span class="gl-font-weight-bold">{{ tooltipContent }}</span>
        </p>
      </template>
    </gl-line-chart>
    <gl-alert v-else variant="info" :dismissible="false" class="gl-mt-3">
      {{ error }}
    </gl-alert>
  </div>
</template>
