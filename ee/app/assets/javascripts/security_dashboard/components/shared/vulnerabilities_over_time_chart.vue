<script>
import { GlTooltipDirective, GlTableLite, GlLoadingIcon } from '@gitlab/ui';
import { GlSparklineChart } from '@gitlab/ui/dist/charts';
import { SEVERITY_LEVELS, DAYS } from 'ee/security_dashboard/store/constants';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import { firstAndLastY } from '~/lib/utils/chart_utils';
import {
  formatDate,
  differenceInMilliseconds,
  millisecondsPerDay,
} from '~/lib/utils/datetime_utility';
import { formattedChangeInPercent } from '~/lib/utils/number_utils';
import { s__, sprintf } from '~/locale';
import ChartButtons from './vulnerabilities_over_time_chart_buttons.vue';

const ISO_DATE = 'isoDate';
const TH_CLASS = 'gl-bg-white!';
const TD_CLASS = 'gl-border-none!';
const TH_CLASS_TEXT_RIGHT = `${TH_CLASS} gl-text-right`;
const TD_CLASS_TEXT_RIGHT = `${TD_CLASS} gl-text-right`;

export default {
  components: {
    ChartButtons,
    GlSparklineChart,
    GlTableLite,
    GlLoadingIcon,
    SeverityBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['groupFullPath'],
  props: {
    query: { type: Object, required: true },
  },
  data() {
    return {
      vulnerabilitiesHistory: {},
      vulnerabilitiesHistoryDayRange: DAYS.thirty,
      errorLoadingVulnerabilitiesHistory: false,
    };
  },
  days: Object.values(DAYS),
  fields: [
    {
      key: 'severityLevel',
      label: s__('VulnerabilityChart|Severity'),
      thClass: TH_CLASS,
      tdClass: TD_CLASS,
    },
    {
      key: 'chartData',
      label: '',
      thClass: TH_CLASS,
      tdClass: `${TD_CLASS} gl-w-full`,
    },
    {
      key: 'changeInPercent',
      label: '%',
      thClass: TH_CLASS_TEXT_RIGHT,
      tdClass: TD_CLASS_TEXT_RIGHT,
    },
    {
      key: 'currentVulnerabilitiesCount',
      label: '#',
      thClass: TH_CLASS_TEXT_RIGHT,
      tdClass: TD_CLASS_TEXT_RIGHT,
    },
  ],
  severityLevels: [
    SEVERITY_LEVELS.critical,
    SEVERITY_LEVELS.high,
    SEVERITY_LEVELS.medium,
    SEVERITY_LEVELS.low,
  ].map((l) => l.toLowerCase()),
  apollo: {
    vulnerabilitiesHistory: {
      query() {
        return this.query;
      },
      variables() {
        return {
          fullPath: this.groupFullPath,
          startDate: formatDate(new Date(this.startDate), ISO_DATE),
          endDate: this.formattedEndDateCursor,
        };
      },
      update(results) {
        return this.processRawData(results);
      },
      error() {
        this.errorLoadingVulnerabilitiesHistory = true;
      },
    },
  },
  computed: {
    startDate() {
      return differenceInMilliseconds(millisecondsPerDay * this.vulnerabilitiesHistoryDayRange);
    },
    endDateCursor() {
      return Date.now();
    },
    formattedEndDateCursor() {
      return formatDate(new Date(this.endDateCursor), ISO_DATE);
    },
    charts() {
      const { severityLevels } = this.$options;

      return severityLevels.map((severityLevel) => {
        const history = Object.entries(this.vulnerabilitiesHistory[severityLevel] || {});
        const chartData = history.length ? history : this.emptyDataSet;
        const [pastCount, currentCount] = firstAndLastY(chartData);
        const changeInPercent = formattedChangeInPercent(pastCount, currentCount);

        return {
          severityLevel,
          chartData,
          changeInPercent,
          currentVulnerabilitiesCount: currentCount,
        };
      });
    },
    dateInfo() {
      return sprintf(s__('VulnerabilityChart|%{formattedStartDate} to today'), {
        formattedStartDate: formatDate(this.startDate, 'mmmm dS'),
      });
    },
    emptyDataSet() {
      const formattedStartDate = formatDate(this.startDate, ISO_DATE);
      const formattedEndDate = formatDate(Date.now(), ISO_DATE);
      return [
        [formattedStartDate, 0],
        [formattedEndDate, 0],
      ];
    },
    isLoadingHistory() {
      return this.$apollo.queries.vulnerabilitiesHistory.loading;
    },
  },
  watch: {
    startDate() {
      this.$apollo.queries.vulnerabilitiesHistory.refetch();
    },
  },
  methods: {
    setVulnerabilitiesHistoryDayRange(days) {
      this.vulnerabilitiesHistory = {};
      this.vulnerabilitiesHistoryDayRange = days;
    },
    processRawData(results) {
      let { vulnerabilitiesCountByDay } = results;

      if (this.groupFullPath) {
        vulnerabilitiesCountByDay = results.group.vulnerabilitiesCountByDay;
      }

      const vulnerabilitiesData = vulnerabilitiesCountByDay.nodes.reduce(
        (acc, v) => {
          const { date, ...severities } = v;
          Object.keys(severities).forEach((severity) => {
            acc[severity] = acc[severity] || {};
            acc[severity][date] = v[severity];
          }, {});

          return acc;
        },
        { ...this.vulnerabilitiesHistory },
      );

      // backend provide the data not sorted - we need to sort it by day first.
      return Object.keys(vulnerabilitiesData).reduce((acc, severity) => {
        acc[severity] = {};
        Object.keys(vulnerabilitiesData[severity])
          .sort()
          .forEach((day) => {
            acc[severity][day] = vulnerabilitiesData[severity][day];
          }, {});

        return acc;
      }, {});
    },
  },
};
</script>

<template>
  <section class="gl-border-solid gl-rounded-base gl-border-1 gl-border-gray-100">
    <div class="gl-p-5">
      <header id="vulnerability-chart-header">
        <h4 class="gl-my-0">
          {{ __('Vulnerabilities over time') }}
        </h4>
        <p
          v-if="!isLoadingHistory"
          data-testid="timeInfo"
          class="gl-text-gray-500 js-vulnerabilities-chart-time-info"
        >
          {{ dateInfo }}
        </p>
      </header>
      <chart-buttons
        v-if="!isLoadingHistory"
        :days="$options.days"
        :active-day="vulnerabilitiesHistoryDayRange"
        @days-selected="setVulnerabilitiesHistoryDayRange"
      />
    </div>

    <gl-loading-icon v-if="isLoadingHistory" size="lg" class="gl-my-12" />
    <gl-table-lite
      v-else
      :fields="$options.fields"
      :items="charts"
      borderless
      class="js-vulnerabilities-chart-severity-level-breakdown gl-mb-3"
    >
      <template #head(changeInPercent)="{ label }">
        <span v-gl-tooltip :title="__('Difference between start date and now')">{{ label }}</span>
      </template>

      <template #head(currentVulnerabilitiesCount)="{ label }">
        <span v-gl-tooltip :title="__('Current vulnerabilities count')">{{ label }}</span>
      </template>

      <template #cell(severityLevel)="{ value }">
        <severity-badge :ref="`severityBadge${value}`" :severity="value" />
      </template>
      <template #cell(chartData)="{ item }">
        <div class="gl-relative gl-p-5">
          <gl-sparkline-chart
            :ref="`sparklineChart${item.severityLevel}`"
            :height="32"
            :data="item.chartData"
            :tooltip-label="__('Vulnerabilities')"
            :show-last-y-value="false"
            class="gl-absolute gl-w-full gl-top-0 gl-left-0"
          />
        </div>
      </template>
      <template #cell(changeInPercent)="{ value }">
        <span ref="changeInPercent">{{ value }}</span>
      </template>
      <template #cell(currentVulnerabilitiesCount)="{ value }">
        <span ref="currentVulnerabilitiesCount">{{ value }}</span>
      </template>
    </gl-table-lite>
  </section>
</template>
