<script>
import { GlEmptyState, GlLink, GlLoadingIcon, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import { GlSingleStat, GlLineChart } from '@gitlab/ui/dist/charts';
import CHART_EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/chart-empty-state.svg?url';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { formatDate, nSecondsBefore } from '~/lib/utils/datetime_utility';
import { captureException } from '~/ci/runner/sentry_utils';
import { createAlert } from '~/alert';

import runnerWaitTimes from 'ee/ci/runner/graphql/performance/runner_wait_times.query.graphql';
import runnerWaitTimeHistoryQuery from 'ee/ci/runner/graphql/performance/runner_wait_time_history.query.graphql';
import {
  runnerWaitTimeQueryData,
  runnerWaitTimeHistoryQueryData,
} from 'ee/ci/runner/runner_performance_utils';

export default {
  name: 'RunnerWaitTimes',
  components: {
    HelpPopover,
    GlEmptyState,
    GlLink,
    GlLoadingIcon,
    GlSkeletonLoader,
    GlSprintf,
    GlSingleStat,
    GlLineChart,
  },
  apollo: {
    waitTimes: {
      query: runnerWaitTimes,
      update({ runners }) {
        return runners?.jobsStatistics?.queuedDuration;
      },
      error(error) {
        this.handlerError(error);
      },
    },
    waitTimeHistory: {
      query: runnerWaitTimeHistoryQuery,
      variables() {
        const fromTime = nSecondsBefore(new Date(), 60 * 60 * 3).toISOString(); // last 3 hours
        const toTime = new Date().toISOString();

        return { fromTime, toTime };
      },
      update({ ciQueueingHistory }) {
        return ciQueueingHistory?.timeSeries;
      },
      error(error) {
        if (error.message.includes('Feature clickhouse_ci_analytics not enabled')) {
          // Ignore error and display empty chart when `clickhouse_ci_analytics` is not enabled
          // TODO Remove this check when https://gitlab.com/gitlab-org/gitlab/-/issues/424498 is
          // rolled out.
          return;
        }
        this.handlerError(error);
      },
    },
  },
  computed: {
    waitTimesLoading() {
      return this.$apollo.queries.waitTimes.loading;
    },
    waitTimeHistoryLoading() {
      return this.$apollo.queries.waitTimeHistory.loading;
    },
    waitTimesStatsData() {
      return runnerWaitTimeQueryData(this.waitTimes);
    },
    waitTimeHistoryChartData() {
      return runnerWaitTimeHistoryQueryData(this.waitTimeHistory);
    },
  },
  methods: {
    handlerError(error) {
      createAlert({ message: error.message });
      captureException({ error, component: this.$options.name });
    },
  },
  jobDurationHelpPagePath: helpPagePath('ci/runners/runners_scope', {
    anchor: 'view-statistics-for-runner-performance',
  }),
  chartOption: {
    xAxis: {
      name: s__('Runners|UTC Time'),
      type: 'time',
      axisLabel: {
        formatter: (value) => formatDate(value, 'HH:MM', true),
      },
    },
    yAxis: {
      name: s__('Runners|Wait time (secs)'),
    },
  },
  CHART_EMPTY_STATE_SVG_URL,
};
</script>
<template>
  <div class="gl-border gl-rounded-base gl-p-5">
    <div class="gl-display-flex">
      <h2 class="gl-font-lg gl-mt-0">
        {{ s__('Runners|Wait time to pick a job') }}
        <help-popover trigger-class="gl-vertical-align-baseline">
          <gl-sprintf
            :message="
              s__(
                'Runners|The time it takes for an instance runner to pick up a job. Jobs waiting for runners are in the pending state. %{linkStart}How is this calculated?%{linkEnd}',
              )
            "
          >
            <template #link="{ content }">
              <gl-link class="gl-reset-font-size" :href="$options.jobDurationHelpPagePath">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
        </help-popover>
      </h2>
      <gl-loading-icon v-if="waitTimesLoading || waitTimeHistoryLoading" class="gl-ml-auto" />
    </div>

    <div class="gl-display-flex gl-flex-wrap gl-gap-3">
      <gl-single-stat
        v-for="stat in waitTimesStatsData"
        :key="stat.key"
        :title="stat.title"
        :value="stat.value"
        :unit="s__('Units|sec')"
      />
    </div>
    <div>
      <div
        v-if="waitTimeHistoryLoading && !waitTimeHistoryChartData.length"
        class="gl-py-4 gl--flex-center"
      >
        <gl-skeleton-loader :equal-width-lines="true" />
      </div>
      <gl-empty-state
        v-else-if="!waitTimeHistoryChartData.length"
        :svg-path="$options.CHART_EMPTY_STATE_SVG_URL"
        :description="s__('Runners|No jobs have been run by instance runners in the past 3 hours.')"
      />
      <gl-line-chart
        v-else
        :include-legend-avg-max="false"
        :data="waitTimeHistoryChartData"
        :option="$options.chartOption"
      />
    </div>
  </div>
</template>
