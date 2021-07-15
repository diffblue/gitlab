<script>
import { GlResizeObserverDirective as GlResizeObserver } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import dateFormat from 'dateformat';
import { merge } from 'lodash';
import { __, n__, s__, sprintf } from '~/locale';
import commonChartOptions from './common_chart_options';

export default {
  directives: {
    GlResizeObserver,
  },
  components: {
    GlLineChart,
  },
  props: {
    startDate: {
      type: String,
      required: true,
    },
    dueDate: {
      type: String,
      required: true,
    },
    openIssuesCount: {
      type: Array,
      required: false,
      default: () => [],
    },
    openIssuesWeight: {
      type: Array,
      required: false,
      default: () => [],
    },
    issuesSelected: {
      type: Boolean,
      required: false,
      default: true,
    },
    showTitle: {
      type: Boolean,
      required: false,
      default: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      tooltip: {
        title: '',
        content: '',
      },
    };
  },
  computed: {
    dataSeries() {
      let name;
      let data;

      if (this.issuesSelected) {
        name = s__('BurndownChartLabel|Open issues');
        data = this.openIssuesCount;
      } else {
        name = s__('BurndownChartLabel|Open issue weight');
        data = this.openIssuesWeight;
      }

      const series = [
        {
          name,
          data,
        },
      ];

      if (data.length > 0) {
        const zeroStart = [this.startDate, 0];
        const firstNonZero = data.find((dataObj) => dataObj[1] !== 0) || zeroStart;
        const idealStart = [this.startDate, firstNonZero[1]];
        const idealEnd = [this.dueDate, 0];
        const idealData = [idealStart, idealEnd];

        series.push({
          name: __('Guideline'),
          data: idealData,
          silent: true,
          symbolSize: 0,
          lineStyle: {
            color: '#ddd',
            type: 'dashed',
          },
        });
      }

      return series;
    },
    options() {
      return merge({}, commonChartOptions, {
        xAxis: {
          min: this.startDate,
          max: this.dueDate,
        },
        yAxis: {
          name: this.issuesSelected ? __('Total issues') : __('Total weight'),
        },
      });
    },
  },
  methods: {
    setChart(chart) {
      this.chart = chart;
    },
    onResize() {
      this.chart?.resize();
    },
    formatTooltipText(params) {
      const [seriesData] = params.seriesData;
      if (!seriesData) {
        return;
      }

      this.tooltip.title = dateFormat(params.value, 'dd mmm yyyy');

      if (this.issuesSelected) {
        this.tooltip.content = n__('%d open issue', '%d open issues', seriesData.value[1]);
      } else {
        this.tooltip.content = sprintf(__('%{total} open issue weight'), {
          total: seriesData.value[1],
        });
      }
    },
  },
};
</script>

<template>
  <div data-qa-selector="burndown_chart">
    <div v-if="showTitle" class="burndown-header d-flex align-items-center">
      <h3>{{ __('Burndown chart') }}</h3>
    </div>
    <gl-line-chart
      v-if="!loading"
      v-gl-resize-observer="onResize"
      class="burndown-chart js-burndown-chart"
      :data="dataSeries"
      :option="options"
      :format-tooltip-text="formatTooltipText"
      :include-legend-avg-max="false"
      @created="setChart"
    >
      <template #tooltip-title>{{ tooltip.title }}</template>
      <template #tooltip-content>{{ tooltip.content }}</template>
    </gl-line-chart>
  </div>
</template>
