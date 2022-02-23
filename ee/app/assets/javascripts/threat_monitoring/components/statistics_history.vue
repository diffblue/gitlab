<script>
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';

import { COLORS, DATE_FORMATS, TIME } from './constants';

export default {
  name: 'StatisticsHistoryChart',
  components: {
    GlAreaChart,
  },
  props: {
    data: {
      type: Object,
      required: true,
      validator: ({ anomalous, nominal, from, to }) =>
        Boolean(anomalous?.title && anomalous?.values) &&
        Boolean(nominal?.title && nominal?.values) &&
        from &&
        to,
    },
    yLegend: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      chartInstance: null,
      tooltipSeriesData: null,
      tooltipTitle: '',
    };
  },
  computed: {
    chartData() {
      const { anomalous, nominal } = this.data;
      const anomalousStyle = { color: COLORS.anomalous };
      const nominalStyle = { color: COLORS.nominal };

      return [
        {
          name: anomalous.title,
          data: anomalous.values,
          areaStyle: anomalousStyle,
          lineStyle: anomalousStyle,
          itemStyle: anomalousStyle,
        },
        {
          name: nominal.title,
          data: nominal.values,
          areaStyle: nominalStyle,
          lineStyle: nominalStyle,
          itemStyle: nominalStyle,
        },
      ];
    },
    chartOptions() {
      const { from, to } = this.data;

      return {
        xAxis: {
          name: TIME,
          type: 'time',
          axisLabel: {
            formatter: (value) => dateFormat(value, DATE_FORMATS.defaultDate),
          },
          min: from,
          max: to,
        },
        yAxis: {
          name: this.yLegend,
        },
      };
    },
  },
  methods: {
    formatTooltipText({ seriesData }) {
      this.tooltipSeriesData = seriesData;
      const [timestamp] = seriesData[0].value;
      this.tooltipTitle = dateFormat(timestamp, DATE_FORMATS.defaultDateTime);
    },
    onChartCreated(chartInstance) {
      this.chartInstance = chartInstance;
    },
  },
};
</script>

<template>
  <gl-area-chart
    :responsive="true"
    :data="chartData"
    :option="chartOptions"
    :include-legend-avg-max="false"
    :format-tooltip-text="formatTooltipText"
    @created="onChartCreated"
  >
    <template #tooltip-title>
      <div>{{ tooltipTitle }} ({{ chartOptions.xAxis.name }})</div>
    </template>

    <template #tooltip-content>
      <div v-for="series in tooltipSeriesData" :key="series.seriesName" class="d-flex">
        <div class="flex-grow-1 mr-5">{{ series.seriesName }}</div>
        <div class="font-weight-bold">{{ series.value[1] }}</div>
      </div>
    </template>
  </gl-area-chart>
</template>
