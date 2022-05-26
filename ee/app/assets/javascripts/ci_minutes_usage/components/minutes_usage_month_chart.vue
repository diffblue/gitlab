<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { formatDate } from '~/lib/utils/datetime_utility';
import {
  USAGE_BY_MONTH,
  NO_CI_MINUTES_MSG,
  X_AXIS_MONTH_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_PROJECT_LABEL,
  formatWithUtc,
} from '../constants';
import { getUsageDataByYear, getSortedYears } from '../utils';

export default {
  components: {
    GlAreaChart,
    GlDropdown,
    GlDropdownItem,
  },
  USAGE_BY_MONTH,
  NO_CI_MINUTES_MSG,
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
          name: Y_AXIS_PROJECT_LABEL,
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
          name: this.$options.USAGE_BY_MONTH,
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
          .map((cur) => [formatDate(cur.monthIso8601, 'mmm yyyy', formatWithUtc), cur.minutes]);
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
  <div>
    <div class="gl-display-flex gl-mt-7 gl-mb-3">
      <div class="gl-flex-grow-1"></div>
      <gl-dropdown :text="selectedYear" data-testid="minutes-usage-month-dropdown" right>
        <gl-dropdown-item
          v-for="year in years"
          :key="year"
          :is-checked="selectedYear === year"
          is-check-item
          data-testid="minutes-usage-month-dropdown-item"
          @click="changeSelectedYear(year)"
        >
          {{ year }}
        </gl-dropdown-item>
      </gl-dropdown>
    </div>
    <gl-area-chart class="gl-mb-3" :data="chartData" :option="chartOptions" responsive :width="0" />
  </div>
</template>
