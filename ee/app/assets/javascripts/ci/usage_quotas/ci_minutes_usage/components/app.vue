<script>
import { GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import MinutesUsageMonthChart from 'ee/ci/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import MinutesUsageProjectChart from 'ee/ci/ci_minutes_usage/components/minutes_usage_project_chart.vue';
import SharedRunnerUsageMonthChart from 'ee/ci/ci_minutes_usage/components/shared_runner_usage_month_chart.vue';
import NoMinutesAlert from 'ee/ci/ci_minutes_usage/components/no_minutes_alert.vue';
import {
  USAGE_BY_MONTH_HEADER,
  USAGE_BY_PROJECT_HEADER,
  CI_CD_MINUTES_USAGE,
  SHARED_RUNNER_USAGE,
  SHARED_RUNNER_POPOVER_OPTIONS,
} from 'ee/ci/ci_minutes_usage/constants';
import getCiMinutesUsageGroup from '../graphql/queries/ci_minutes_namespace.query.graphql';

export default {
  USAGE_BY_MONTH_HEADER,
  USAGE_BY_PROJECT_HEADER,
  CI_CD_MINUTES_USAGE,
  SHARED_RUNNER_USAGE,
  SHARED_RUNNER_POPOVER_OPTIONS,
  components: {
    GlLoadingIcon,
    GlTab,
    GlTabs,
    HelpPopover,
    MinutesUsageMonthChart,
    MinutesUsageProjectChart,
    NoMinutesAlert,
    SharedRunnerUsageMonthChart,
  },
  inject: ['namespaceId'],
  data() {
    return {
      ciMinutesUsage: [],
    };
  },
  apollo: {
    ciMinutesUsage: {
      query: getCiMinutesUsageGroup,
      variables() {
        return {
          namespaceId: convertToGraphQLId(TYPE_GROUP, this.namespaceId),
        };
      },
      update(res) {
        return res?.ciMinutesUsage?.nodes;
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.ciMinutesUsage.loading;
    },
    borderStyles() {
      return 'gl-border-b-solid gl-border-gray-200 gl-border-b-1';
    },
    hasMinutes() {
      return this.ciMinutesUsage.length > 0;
    },
  },
};
</script>
<template>
  <div :class="borderStyles" class="gl-my-7">
    <gl-loading-icon v-if="loading" size="lg" class="gl-mb-5" />
    <template v-else>
      <h4 class="gl-font-lg gl-mb-5">{{ $options.USAGE_BY_MONTH_HEADER }}</h4>
      <gl-tabs>
        <gl-tab :title="$options.CI_CD_MINUTES_USAGE">
          <no-minutes-alert v-if="!hasMinutes" />
          <minutes-usage-month-chart
            v-else
            :class="borderStyles"
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
          <no-minutes-alert v-if="!hasMinutes" />
          <minutes-usage-project-chart
            v-else
            :minutes-usage-data="ciMinutesUsage"
            display-shared-runner-data
            data-testid="shared-runner-by-project"
          />
        </gl-tab>
      </gl-tabs>
    </template>
  </div>
</template>
