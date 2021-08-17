<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { keyBy } from 'lodash';
import {
  USAGE_BY_PROJECT,
  X_AXIS_PROJECT_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_LABEL,
} from '../constants';

export default {
  USAGE_BY_PROJECT,
  X_AXIS_PROJECT_LABEL,
  X_AXIS_CATEGORY,
  Y_AXIS_LABEL,
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
  },
  data() {
    return {
      selectedMonth: '',
    };
  },
  computed: {
    chartData() {
      return [
        {
          data: this.getUsageDataSelectedMonth,
        },
      ];
    },
    usageDataByMonth() {
      return keyBy(this.minutesUsageData, 'month');
    },
    getUsageDataSelectedMonth() {
      return this.usageDataByMonth[this.selectedMonth]?.projects?.nodes.map((cur) => [
        cur.name,
        cur.minutes,
      ]);
    },
    months() {
      return this.minutesUsageData.map((cur) => cur.month);
    },
    isDataEmpty() {
      return this.minutesUsageData.length === 0 && this.selectedMonth.length === 0;
    },
  },
  watch: {
    months() {
      this.setFirstMonthDropdown();
    },
  },
  mounted() {
    if (!this.isDataEmpty) {
      this.setFirstMonthDropdown();
    }
  },
  methods: {
    changeSelectedMonth(month) {
      this.selectedMonth = month;
    },
    setFirstMonthDropdown() {
      [this.selectedMonth] = this.months;
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-my-3">
      <h5 class="gl-flex-grow-1">{{ $options.USAGE_BY_PROJECT }}</h5>
      <gl-dropdown v-if="!isDataEmpty" :text="selectedMonth" data-testid="project-month-dropdown">
        <gl-dropdown-item
          v-for="(month, index) in months"
          :key="index"
          :is-checked="selectedMonth === month"
          is-check-item
          data-testid="month-dropdown-item"
          @click="changeSelectedMonth(month)"
        >
          {{ month }}
        </gl-dropdown-item>
      </gl-dropdown>
    </div>
    <gl-column-chart
      v-if="!isDataEmpty"
      class="gl-mb-3"
      :bars="chartData"
      :y-axis-title="$options.Y_AXIS_LABEL"
      :x-axis-title="$options.X_AXIS_PROJECT_LABEL"
      :x-axis-type="$options.X_AXIS_CATEGORY"
    />
  </div>
</template>
