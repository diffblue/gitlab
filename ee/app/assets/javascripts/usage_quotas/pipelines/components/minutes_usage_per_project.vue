<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import {
  CI_CD_MINUTES_USAGE,
  SHARED_RUNNER_USAGE,
  SHARED_RUNNER_POPOVER_OPTIONS,
} from '../constants';
import { getUsageDataByYearByMonthAsObject } from '../utils';
import MinutesUsagePerProjectChart from './minutes_usage_per_project_chart.vue';
import NoMinutesAlert from './no_minutes_alert.vue';

export default {
  name: 'MinutesUsagePerProject',
  components: {
    MinutesUsagePerProjectChart,
    NoMinutesAlert,
    HelpPopover,
    GlTab,
    GlTabs,
  },
  props: {
    projectsCiMinutesUsage: {
      type: Array,
      required: false,
      default: () => [],
    },
    selectedYear: {
      type: Number,
      required: true,
    },
    selectedMonth: {
      type: Number,
      required: true,
    },
  },
  computed: {
    usageDataByYearObject() {
      return getUsageDataByYearByMonthAsObject(this.projectsCiMinutesUsage);
    },
    hasCiMinutes() {
      return this.projectsCiMinutesUsage.some((usage) => usage.minutes > 0);
    },
    hasSharedRunnersMinutes() {
      return this.projectsCiMinutesUsage.some((usage) => usage.sharedRunnersDuration > 0);
    },
  },
  CI_CD_MINUTES_USAGE,
  SHARED_RUNNER_USAGE,
  SHARED_RUNNER_POPOVER_OPTIONS,
};
</script>

<template>
  <gl-tabs>
    <gl-tab :title="$options.CI_CD_MINUTES_USAGE">
      <no-minutes-alert v-if="!hasCiMinutes" />
      <minutes-usage-per-project-chart
        v-else
        :usage-data-by-year="usageDataByYearObject"
        :selected-year="selectedYear"
        :selected-month="selectedMonth"
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
      <minutes-usage-per-project-chart
        v-else
        :usage-data-by-year="usageDataByYearObject"
        :selected-year="selectedYear"
        :selected-month="selectedMonth"
        display-shared-runner-data
        data-testid="shared-runner-by-project"
      />
    </gl-tab>
  </gl-tabs>
</template>
