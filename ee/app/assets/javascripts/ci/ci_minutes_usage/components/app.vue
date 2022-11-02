<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import getCiMinutesUsage from '../graphql/queries/ci_minutes.query.graphql';
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
  components: {
    GlTab,
    GlTabs,
    HelpPopover,
    NoMinutesAlert,
    MinutesUsageMonthChart,
    MinutesUsageProjectChart,
    SharedRunnerUsageMonthChart,
  },
  apollo: {
    ciMinutesUsage: {
      query: getCiMinutesUsage,
      update(res) {
        return res?.ciMinutesUsage?.nodes;
      },
    },
  },
  data() {
    return {
      ciMinutesUsage: [],
    };
  },
  computed: {
    hasMinutes() {
      return this.ciMinutesUsage.length > 0;
    },
  },
  USAGE_BY_MONTH_HEADER,
  USAGE_BY_PROJECT_HEADER,
  CI_CD_MINUTES_USAGE,
  SHARED_RUNNER_USAGE,
  SHARED_RUNNER_POPOVER_OPTIONS,
};
</script>
<template>
  <div class="gl-border-b-solid gl-border-gray-200 gl-border-b-1 gl-mb-3 gl-pl-4">
    <h4 class="gl-font-lg gl-mb-5">{{ $options.USAGE_BY_MONTH_HEADER }}</h4>
    <gl-tabs>
      <gl-tab :title="$options.CI_CD_MINUTES_USAGE">
        <no-minutes-alert v-if="!hasMinutes" />
        <minutes-usage-month-chart
          v-else
          class="gl-border-b-solid gl-border-gray-200 gl-border-b-1"
          :ci-minutes-usage="ciMinutesUsage"
        />
      </gl-tab>
      <gl-tab>
        <template #title>
          <div id="shared-runner-message-popover-container" class="gl-display-flex">
            <span class="gl-mr-2">{{ $options.SHARED_RUNNER_USAGE }}</span>
            <help-popover :options="$options.SHARED_RUNNER_POPOVER_OPTIONS" />
          </div>
        </template>
        <no-minutes-alert v-if="!hasMinutes" />
        <shared-runner-usage-month-chart v-else :ci-minutes-usage="ciMinutesUsage" />
      </gl-tab>
    </gl-tabs>
    <h4 class="gl-font-lg gl-mb-5">{{ $options.USAGE_BY_PROJECT_HEADER }}</h4>
    <gl-tabs>
      <gl-tab :title="$options.CI_CD_MINUTES_USAGE">
        <no-minutes-alert v-if="!hasMinutes" />
        <minutes-usage-project-chart v-else :minutes-usage-data="ciMinutesUsage" />
      </gl-tab>
      <gl-tab>
        <template #title>
          <div id="shared-runner-message-popover-container" class="gl-display-flex">
            <span class="gl-mr-2">{{ $options.SHARED_RUNNER_USAGE }}</span>
            <help-popover :options="$options.popoverOptions" />
          </div>
        </template>
        <no-minutes-alert v-if="!hasMinutes" />
        <minutes-usage-project-chart
          v-else
          :minutes-usage-data="ciMinutesUsage"
          display-shared-runner-data
        />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
