<script>
import { GlDropdown, GlDropdownItem, GlFormGroup } from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { isEmpty } from 'lodash';
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
    GlFormGroup,
  },
  props: {
    displaySharedRunnerData: {
      type: Boolean,
      required: false,
      default: false,
    },
    usageDataByYear: {
      type: Object,
      required: true,
    },
    selectedYear: {
      type: String,
      required: true,
    },
  },
  chartOptions: {
    yAxis: {
      axisLabel: {
        formatter: (val) => val,
      },
    },
  },
  data() {
    return {
      selectedMonth: '',
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
    availableMonths() {
      this.setFirstMonthDropdown();
    },
  },
  mounted() {
    this.setFirstMonthDropdown();
  },
  methods: {
    changeSelectedMonth(monthIso8601) {
      this.selectedMonth = monthIso8601;
    },
    setFirstMonthDropdown() {
      [this.selectedMonth] = this.availableMonths;
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-mt-3 gl-mb-3">
      <gl-form-group :label="s__('UsageQuota|Filter chart by month')">
        <gl-dropdown :text="selectedMonth" data-testid="minutes-usage-project-month-dropdown">
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
      </gl-form-group>
    </div>
    <gl-column-chart
      class="gl-mb-3"
      responsive
      :width="0"
      :bars="chartData"
      :option="$options.chartOptions"
      :y-axis-title="yAxisTitle"
      :x-axis-title="$options.X_AXIS_PROJECT_LABEL"
      :x-axis-type="$options.X_AXIS_CATEGORY"
    />
  </div>
</template>
