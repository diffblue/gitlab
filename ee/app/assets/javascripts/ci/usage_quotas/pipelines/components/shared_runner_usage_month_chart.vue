<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { s__ } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import { X_AXIS_MONTH_LABEL, X_AXIS_CATEGORY, Y_AXIS_SHARED_RUNNER_LABEL } from '../constants';
import { getUsageDataByYear, getSortedYears } from '../utils';

export default {
  components: {
    GlAreaChart,
    GlDropdown,
    GlDropdownItem,
  },
  i18n: {
    seriesName: s__('CICDAnalytics|Shared runner pipeline minute duration by month'),
    noSharedRunnerMinutesUsage: s__('CICDAnalytics|No shared runner minute usage data available'),
  },
  props: {
    ciMinutesUsage: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      selectedYear: '',
      usageDataByYear: {},
    };
  },
  computed: {
    chartOptions() {
      return {
        xAxis: {
          name: X_AXIS_MONTH_LABEL,
          type: X_AXIS_CATEGORY,
        },
        yAxis: {
          name: Y_AXIS_SHARED_RUNNER_LABEL,
          axisLabel: {
            formatter: (val) => val,
          },
        },
      };
    },
    chartData() {
      return [
        {
          data: this.getUsageDataSelectedYear,
          name: this.$options.i18n.seriesName,
        },
      ];
    },
    getUsageDataSelectedYear() {
      if (this.usageDataByYear && this.selectedYear) {
        return this.usageDataByYear[this.selectedYear]
          .slice()
          .sort((a, b) => {
            return new Date(a.monthIso8601) - new Date(b.monthIso8601);
          })
          .map((cur) => [
            formatDate(cur.monthIso8601, 'mmm yyyy'),
            (cur.sharedRunnersDuration / 60).toFixed(2),
          ]);
      }
      return [];
    },
    years() {
      return getSortedYears(this.usageDataByYear);
    },
  },
  watch: {
    years() {
      this.setFirstYearDropdown();
    },
  },
  mounted() {
    this.usageDataByYear = getUsageDataByYear(this.ciMinutesUsage);
    this.setFirstYearDropdown();
  },
  methods: {
    changeSelectedYear(year) {
      this.selectedYear = year;
    },
    setFirstYearDropdown() {
      [this.selectedYear] = this.years;
    },
  },
};
</script>
<template>
  <div class="gl-mt-4">
    <div class="gl-display-flex gl-mt-7 gl-mb-3">
      <div class="gl-flex-grow-1"></div>
      <gl-dropdown :text="selectedYear" data-testid="shared-runner-usage-month-dropdown" right>
        <gl-dropdown-item
          v-for="year in years"
          :key="year"
          :is-checked="selectedYear === year"
          is-check-item
          data-testid="shared-runner-usage-month-dropdown-item"
          @click="changeSelectedYear(year)"
        >
          {{ year }}
        </gl-dropdown-item>
      </gl-dropdown>
    </div>
    <gl-area-chart :data="chartData" :option="chartOptions" :width="0" responsive />
  </div>
</template>
