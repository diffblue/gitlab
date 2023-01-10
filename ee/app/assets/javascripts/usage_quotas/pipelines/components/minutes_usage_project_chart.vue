<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { isEmpty } from 'lodash';
import { formatDate } from '~/lib/utils/datetime_utility';
import { formatYearMonthData, getSortedYears } from '../utils';
import {
  USAGE_BY_PROJECT,
  X_AXIS_PROJECT_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_PROJECT_LABEL,
  Y_AXIS_SHARED_RUNNER_LABEL,
  NO_CI_MINUTES_MSG,
} from '../constants';

export default {
  USAGE_BY_PROJECT,
  X_AXIS_PROJECT_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_PROJECT_LABEL,
  Y_AXIS_SHARED_RUNNER_LABEL,
  NO_CI_MINUTES_MSG,
  components: {
    GlColumnChart,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    minutesUsageData: {
      type: Array,
      required: true,
    },
    displaySharedRunnerData: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selectedMonth: '',
      selectedYear: '',
      formattedData: [],
    };
  },
  computed: {
    chartData() {
      return [
        {
          data: this?.getUsageSelectedYearMonth,
        },
      ];
    },
    chartOptions() {
      return {
        yAxis: {
          axisLabel: {
            formatter: (val) => val,
          },
        },
      };
    },
    usageDataByYear() {
      return this.formattedData.length > 0
        ? this.formattedData.reduce((prev, cur) => {
            if (!prev[cur.year]) {
              // eslint-disable-next-line no-param-reassign
              prev[cur.year] = {};
            }

            // eslint-disable-next-line no-param-reassign
            prev[cur.year][cur.monthName] = cur;
            return prev;
          }, {})
        : [];
    },
    years() {
      return getSortedYears(this?.usageDataByYear);
    },
    availableMonths() {
      if (this.usageDataByYear && this.selectedYear) {
        return Object.keys(this.usageDataByYear[this.selectedYear]);
      }
      return [];
    },
    getDataSelectedMonth() {
      if (this.usageDataByYear && this.selectedYear) {
        return this.usageDataByYear[this.selectedYear][this?.selectedMonth];
      }
      return {};
    },
    getUsageSelectedYearMonth() {
      return !isEmpty(this.getDataSelectedMonth)
        ? this.getDataSelectedMonth.projects.nodes.map((cur) => {
            if (this.displaySharedRunnerData) {
              return [cur.project.name, (cur.sharedRunnersDuration / 60).toFixed(2)];
            }
            return [cur.project.name, cur.minutes];
          })
        : [];
    },
    yAxisTitle() {
      return this.displaySharedRunnerData
        ? this.$options.Y_AXIS_SHARED_RUNNER_LABEL
        : this.$options.Y_AXIS_PROJECT_LABEL;
    },
  },
  watch: {
    years() {
      this.setFirstYearDropdown();
      this.setFirstMonthDropdown();
    },
  },
  mounted() {
    this.setFirstYearDropdown();
    this.setFirstMonthDropdown();

    this.formattedData = formatYearMonthData(this.minutesUsageData, true);
  },
  methods: {
    changeSelectedMonth(monthIso8601) {
      this.selectedMonth = monthIso8601;
    },
    setFirstMonthDropdown() {
      [this.selectedMonth] = this.availableMonths;
    },
    getFormattedMonthYear(monthIso8601) {
      return formatDate(monthIso8601, 'mmm yyyy');
    },
    changeSelectedYear(year) {
      this.selectedYear = year;
      this.setFirstMonthDropdown();
    },
    setFirstYearDropdown() {
      [this.selectedYear] = this.years;
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-mt-7 gl-mb-3">
      <div class="gl-flex-grow-1"></div>
      <gl-dropdown
        :text="selectedYear"
        class="gl-mr-3"
        data-testid="minutes-usage-project-year-dropdown"
        right
      >
        <gl-dropdown-item
          v-for="year in years"
          :key="year"
          :is-checked="selectedYear === year"
          is-check-item
          data-testid="minutes-usage-project-year-dropdown-item"
          @click="changeSelectedYear(year)"
        >
          {{ year }}
        </gl-dropdown-item>
      </gl-dropdown>
      <gl-dropdown :text="selectedMonth" data-testid="minutes-usage-project-month-dropdown" right>
        <gl-dropdown-item
          v-for="month in availableMonths"
          :key="month"
          :is-checked="selectedMonth === month"
          is-check-item
          data-testid="minutes-usage-project-month-dropdown-item"
          @click="changeSelectedMonth(month)"
        >
          {{ month }}
        </gl-dropdown-item>
      </gl-dropdown>
    </div>
    <gl-column-chart
      class="gl-mb-3"
      responsive
      :width="0"
      :bars="chartData"
      :option="chartOptions"
      :y-axis-title="yAxisTitle"
      :x-axis-title="$options.X_AXIS_PROJECT_LABEL"
      :x-axis-type="$options.X_AXIS_CATEGORY"
    />
  </div>
</template>
