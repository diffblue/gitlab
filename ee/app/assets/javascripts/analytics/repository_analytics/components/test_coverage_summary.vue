<script>
import chartEmptyStateIllustration from '@gitlab/svgs/dist/illustrations/chart-empty-state.svg?raw';
import { GlCard, GlSprintf, GlSkeletonLoader, GlPopover } from '@gitlab/ui';
import { GlSingleStat, GlAreaChart } from '@gitlab/ui/dist/charts';
import SafeHtml from '~/vue_shared/directives/safe_html';
import {
  formatDate,
  getTimeago,
  isToday,
  newDateAsLocaleTime,
  timeagoLanguageCode,
} from '~/lib/utils/datetime_utility';
import { SUPPORTED_FORMATS, getFormatter } from '~/lib/utils/unit_format';
import { __ } from '~/locale';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { summaryi18n as i18n } from '../constants';
import getGroupTestCoverage from '../graphql/queries/get_group_test_coverage.query.graphql';

const formatPercent = getFormatter(SUPPORTED_FORMATS.percentHundred);

export default {
  name: 'TestCoverageSummary',
  components: {
    ChartSkeletonLoader,
    GlAreaChart,
    GlCard,
    GlSprintf,
    GlSkeletonLoader,
    GlSingleStat,
    GlPopover,
  },
  directives: {
    SafeHtml,
  },
  inject: {
    groupFullPath: {
      default: '',
    },
    groupName: {
      default: '',
    },
  },
  apollo: {
    group: {
      query: getGroupTestCoverage,
      variables() {
        const THIRTY_DAYS = 30 * 24 * 60 * 60 * 1000; // milliseconds

        return {
          groupFullPath: this.groupFullPath,
          startDate: formatDate(new Date(Date.now() - THIRTY_DAYS), 'yyyy-mm-dd'),
        };
      },
      result({ data }) {
        const groupCoverage = data.group.codeCoverageActivities.nodes;
        const { projectCount, averageCoverage, coverageCount, date } =
          groupCoverage?.[groupCoverage.length - 1] || {};

        this.projectCount = projectCount;
        this.averageCoverage = averageCoverage;
        this.coverageCount = coverageCount;
        this.latestCoverageDate = date;
        this.groupCoverageChartData = [
          {
            name: this.$options.i18n.graphName,
            data: groupCoverage.map((coverage) => [
              coverage.date,
              coverage.averageCoverage,
              coverage.projectCount,
              coverage.coverageCount,
            ]),
          },
        ];
      },
      error() {
        this.hasError = true;
        this.projectCount = null;
        this.averageCoverage = null;
        this.coverageCount = null;
        this.groupCoverageChartData = [];
      },
      watchLoading(isLoading) {
        this.isLoading = isLoading;
      },
    },
  },
  data() {
    return {
      projectCount: null,
      averageCoverage: null,
      coverageCount: null,
      latestCoverageDate: null,
      groupCoverageChartData: [],
      coveragePercentage: null,
      tooltipTitle: null,
      tooltipAverageCoverage: null,
      tooltipProjectCount: null,
      tooltipCoverageCount: null,
      hasError: false,
      isLoading: false,
    };
  },
  computed: {
    isChartEmpty() {
      return !this.groupCoverageChartData?.[0]?.data?.length;
    },
    metrics() {
      return [
        {
          key: 'projectCount',
          value: this.projectCount,
          label: this.$options.i18n.metrics.projectCountLabel,
          popover: this.$options.i18n.metrics.projectCountPopover,
        },
        {
          key: 'averageCoverage',
          value: this.averageCoverage,
          unit: '%',
          label: this.$options.i18n.metrics.averageCoverageLabel,
          popover: this.$options.i18n.metrics.averageCoveragePopover,
        },
        {
          key: 'coverageCount',
          value: this.coverageCount,
          label: this.$options.i18n.metrics.coverageCountLabel,
          popover: this.$options.i18n.metrics.coverageCountPopover,
        },
      ];
    },
    chartOptions() {
      return {
        xAxis: {
          name: this.$options.i18n.xAxisName,
          type: 'time',
          axisLabel: {
            formatter: (value) => formatDate(value, 'mmm dd'),
          },
        },
        yAxis: {
          name: this.$options.i18n.yAxisName,
          type: 'value',
          min: 0,
          max: 100,
          axisLabel: {
            /**
             * We can't do `formatter: formatPercent` because
             * formatter passes in a second argument of index, which
             * formatPercent takes in as the number of decimal points
             * we should include after. This formats 100 as 100.00000%
             * instead of 100%.
             */
            formatter: (value) => formatPercent(value),
          },
        },
      };
    },
    latestCoverageTimeAgo() {
      if (!this.latestCoverageDate) {
        return null;
      }
      if (isToday(newDateAsLocaleTime(this.latestCoverageDate))) {
        return __('today');
      }
      return getTimeago().format(this.latestCoverageDate, timeagoLanguageCode);
    },
  },
  methods: {
    formatTooltipText(params) {
      const [, averageCoverage, projectCount, coverageCount] = params.seriesData[0].data;

      this.tooltipTitle = formatDate(params.value, 'mmm dd');
      this.tooltipAverageCoverage = formatPercent(averageCoverage, 2);
      this.tooltipProjectCount = projectCount;
      this.tooltipCoverageCount = coverageCount;
    },
  },
  i18n,
  chartEmptyStateIllustration,
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-align-items-center">
      <h4 data-testid="test-coverage-header">
        {{ $options.i18n.codeCoverageHeader }}
      </h4>
      <strong class="gl-ml-3 gl-text-gray-600" data-testid="test-coverage-last-updated">
        <gl-sprintf v-if="!isChartEmpty" :message="$options.i18n.lastUpdated">
          <template #timeAgo>{{ latestCoverageTimeAgo }}</template>
        </gl-sprintf>
      </strong>
    </div>
    <div
      class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-my-6 gl-align-items-flex-start"
    >
      <gl-skeleton-loader v-if="isLoading" />
      <template v-for="metric in metrics" v-else>
        <gl-single-stat
          :id="metric.key"
          :key="metric.key"
          class="gl-pr-9 gl-my-4 gl-md-mt-0 gl-md-mb-0"
          :value="`${metric.value || '-'}`"
          :unit="metric.value ? metric.unit : null"
          :title="metric.label"
          :should-animate="true"
        />
        <gl-popover :key="`${metric.key}-popover`" :target="metric.key" :title="metric.label">
          <gl-sprintf :message="metric.popover(metric.value || 0)">
            <template #groupName>{{ groupName }}</template>
            <template #metricValue>{{ metric.value || 0 }}{{ metric.unit }}</template>
          </gl-sprintf>
        </gl-popover>
      </template>
    </div>

    <gl-card>
      <template #header>
        <div class="gl-display-flex gl-align-items-center">
          <h5>{{ $options.i18n.graphCardHeader }}</h5>
          <strong class="gl-font-sm gl-ml-3 gl-text-gray-600">{{
            $options.i18n.graphCardSubheader
          }}</strong>
        </div>
      </template>

      <chart-skeleton-loader v-if="isLoading" data-testid="group-coverage-chart-loading" />

      <div
        v-else-if="isChartEmpty"
        class="d-flex flex-column justify-content-center gl-my-7"
        data-testid="group-coverage-chart-empty"
      >
        <div
          v-safe-html="$options.chartEmptyStateIllustration"
          class="gl-my-5 svg-w-100 d-flex align-items-center"
          data-testid="chart-empty-state-illustration"
        ></div>
        <h5 class="text-center">{{ $options.i18n.emptyChart }}</h5>
      </div>

      <gl-area-chart
        v-else
        :data="groupCoverageChartData"
        :option="chartOptions"
        :include-legend-avg-max="false"
        :format-tooltip-text="formatTooltipText"
        data-testid="group-coverage-chart"
        responsive
      >
        <template #tooltip-title>
          {{ tooltipTitle }}
        </template>
        <template #tooltip-content>
          <gl-sprintf :message="$options.i18n.graphTooltip.averageCoverage">
            <template #averageCoverage> {{ tooltipAverageCoverage }}</template>
          </gl-sprintf>
          <br />
          <gl-sprintf :message="$options.i18n.graphTooltip.projectCount">
            <template #projectCount> {{ tooltipProjectCount }} </template>
          </gl-sprintf>
          <br />
          <gl-sprintf :message="$options.i18n.graphTooltip.coverageCount">
            <template #coverageCount> {{ tooltipCoverageCount }} </template>
          </gl-sprintf>
        </template>
      </gl-area-chart>
    </gl-card>
  </div>
</template>
