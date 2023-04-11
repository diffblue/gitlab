<script>
import { GlDropdown, GlDropdownItem, GlFormGroup, GlTab, GlTabs } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import {
  CI_CD_MINUTES_USAGE,
  SHARED_RUNNER_USAGE,
  SHARED_RUNNER_POPOVER_OPTIONS,
} from '../constants';
import { USAGE_BY_MONTH_HEADER, USAGE_BY_PROJECT_HEADER } from '../../constants';
import { getSortedYears, getUsageDataByYear, getUsageDataByYearObject } from '../utils';
import MinutesUsageMonthChart from './minutes_usage_month_chart.vue';
import MinutesUsageProjectChart from './minutes_usage_project_chart.vue';
import SharedRunnerUsageMonthChart from './shared_runner_usage_month_chart.vue';
import NoMinutesAlert from './no_minutes_alert.vue';

export default {
  name: 'MinutesUsageCharts',
  components: {
    MinutesUsageMonthChart,
    MinutesUsageProjectChart,
    SharedRunnerUsageMonthChart,
    NoMinutesAlert,
    HelpPopover,
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    GlTab,
    GlTabs,
  },
  props: {
    ciMinutesUsage: {
      type: Array,
      required: false,
      default: () => [],
    },
    displaySharedRunnerData: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selectedYear: '',
      usageDataByYear: getUsageDataByYear(this.ciMinutesUsage),
      usageDataByYearObject: getUsageDataByYearObject(this.ciMinutesUsage),
    };
  },
  computed: {
    hasCiMinutes() {
      return Boolean(this.ciMinutesUsage.find((usage) => usage.minutes > 0));
    },
    hasSharedRunnersMinutes() {
      return Boolean(this.ciMinutesUsage.find((usage) => usage.sharedRunnersDuration > 0));
    },
    years() {
      return getSortedYears(this.usageDataByYear);
    },
    availableMonths() {
      if (this.usageDataByYearObject && this.selectedYear) {
        return Object.keys(this.usageDataByYearObject[this.selectedYear]);
      }
      return [];
    },
  },
  watch: {
    years() {
      this.setFirstYearDropdown();
    },
  },
  mounted() {
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
  borderStyles: 'gl-border-b-solid gl-border-gray-200 gl-border-b-1',
  USAGE_BY_MONTH_HEADER,
  USAGE_BY_PROJECT_HEADER,
  CI_CD_MINUTES_USAGE,
  SHARED_RUNNER_USAGE,
  SHARED_RUNNER_POPOVER_OPTIONS,
};
</script>

<template>
  <div :class="$options.borderStyles" class="gl-my-7">
    <div class="gl-display-flex">
      <gl-form-group :label="s__('UsageQuota|Filter charts by year')">
        <gl-dropdown :text="selectedYear" data-testid="minutes-usage-year-dropdown">
          <gl-dropdown-item
            v-for="year in years"
            :key="year"
            :is-checked="selectedYear === year"
            is-check-item
            data-testid="minutes-usage-year-dropdown-item"
            @click="changeSelectedYear(year)"
          >
            {{ year }}
          </gl-dropdown-item>
        </gl-dropdown>
      </gl-form-group>
    </div>
    <h4 class="gl-font-lg gl-mb-3">{{ $options.USAGE_BY_MONTH_HEADER }}</h4>
    <gl-tabs>
      <gl-tab :title="$options.CI_CD_MINUTES_USAGE">
        <no-minutes-alert v-if="!hasCiMinutes" />
        <minutes-usage-month-chart
          v-else
          :selected-year="selectedYear"
          :usage-data-by-year="usageDataByYear"
          data-testid="minutes-by-namespace"
        />
      </gl-tab>
      <gl-tab>
        <template #title>
          <div id="shared-runner-message-popover-container" class="gl-display-flex">
            <span class="gl-mr-2">{{ $options.SHARED_RUNNER_USAGE }}</span>
            <help-popover :options="$options.SHARED_RUNNER_POPOVER_OPTIONS" />
          </div>
        </template>
        <no-minutes-alert v-if="!hasSharedRunnersMinutes" />
        <shared-runner-usage-month-chart
          v-else
          :selected-year="selectedYear"
          :usage-data-by-year="usageDataByYear"
          data-testid="shared-runner-by-namespace"
        />
      </gl-tab>
    </gl-tabs>
    <h4 class="gl-font-lg gl-mb-3">{{ $options.USAGE_BY_PROJECT_HEADER }}</h4>
    <gl-tabs>
      <gl-tab :title="$options.CI_CD_MINUTES_USAGE">
        <no-minutes-alert v-if="!hasCiMinutes" />
        <minutes-usage-project-chart
          v-else
          :usage-data-by-year="usageDataByYearObject"
          :selected-year="selectedYear"
          data-testid="minutes-by-project"
        />
      </gl-tab>
      <gl-tab>
        <template #title>
          <div id="shared-runner-message-popover-container" class="gl-display-flex">
            <span class="gl-mr-2">{{ $options.SHARED_RUNNER_USAGE }}</span>
            <help-popover :options="$options.SHARED_RUNNER_POPOVER_OPTIONS" />
          </div>
        </template>
        <no-minutes-alert v-if="!hasSharedRunnersMinutes" />
        <minutes-usage-project-chart
          v-else
          :usage-data-by-year="usageDataByYearObject"
          :selected-year="selectedYear"
          display-shared-runner-data
          data-testid="shared-runner-by-project"
        />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
