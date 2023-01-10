<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import {
  USAGE_BY_MONTH_HEADER,
  USAGE_BY_PROJECT_HEADER,
  CI_CD_MINUTES_USAGE,
  SHARED_RUNNER_USAGE,
  SHARED_RUNNER_POPOVER_OPTIONS,
} from '../constants';
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
    GlTab,
    GlTabs,
  },
  props: {
    ciMinutesUsage: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    hasCiMinutes() {
      return this.ciMinutesUsage.find((usage) => usage.minutes > 0);
    },
    hasSharedRunnersMinutes() {
      return this.ciMinutesUsage.find((usage) => usage.sharedRunnersDuration > 0);
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
    <h4 class="gl-font-lg gl-mb-5">{{ $options.USAGE_BY_MONTH_HEADER }}</h4>
    <gl-tabs>
      <gl-tab :title="$options.CI_CD_MINUTES_USAGE">
        <no-minutes-alert v-if="!hasCiMinutes" />
        <minutes-usage-month-chart
          v-else
          :class="$options.borderStyles"
          :ci-minutes-usage="ciMinutesUsage"
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
          :ci-minutes-usage="ciMinutesUsage"
          data-testid="shared-runner-by-namespace"
        />
      </gl-tab>
    </gl-tabs>
    <h4 class="gl-font-lg gl-mb-5">{{ $options.USAGE_BY_PROJECT_HEADER }}</h4>
    <gl-tabs>
      <gl-tab :title="$options.CI_CD_MINUTES_USAGE">
        <no-minutes-alert v-if="!hasCiMinutes" />
        <minutes-usage-project-chart
          v-else
          :minutes-usage-data="ciMinutesUsage"
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
          :minutes-usage-data="ciMinutesUsage"
          display-shared-runner-data
          data-testid="shared-runner-by-project"
        />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
