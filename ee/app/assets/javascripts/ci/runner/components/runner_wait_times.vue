<script>
import { GlSprintf, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

import runnerWaitTimes from 'ee/ci/runner/graphql/performance/runner_wait_times.query.graphql';

import { I18N_MEDIAN, I18N_P75, I18N_P90, I18N_P99 } from '../constants';

const EMPTY_PLACEHOLDER = '-';

export default {
  components: {
    HelpPopover,
    GlSprintf,
    GlLink,
    GlLoadingIcon,
    GlSingleStat,
  },
  data() {
    return {
      queuedDuration: {
        p50: EMPTY_PLACEHOLDER,
        p75: EMPTY_PLACEHOLDER,
        p90: EMPTY_PLACEHOLDER,
        p99: EMPTY_PLACEHOLDER,
      },
    };
  },
  apollo: {
    queuedDuration: {
      query: runnerWaitTimes,
      update(data) {
        const { runners } = data;
        return runners?.jobsStatistics?.queuedDuration;
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.queuedDuration.loading;
    },
    stats() {
      const { p50, p75, p90, p99 } = this.queuedDuration;
      return [
        {
          key: 'p50',
          title: I18N_MEDIAN,
          value: p50,
        },
        {
          key: 'p75',
          title: I18N_P75,
          value: p75,
        },
        {
          key: 'p90',
          title: I18N_P90,
          value: p90,
        },
        {
          key: 'p99',
          title: I18N_P99,
          value: p99,
        },
      ];
    },
  },
  jobDurationHelpPagePath: helpPagePath('ci/runners/runners_scope', {
    anchor: 'view-statistics-for-runner-performance',
  }),
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
      <gl-loading-icon v-if="loading" class="gl-ml-auto" />
    </div>

    <div class="gl-display-flex gl-flex-wrap gl-gap-3">
      <gl-single-stat
        v-for="stat in stats"
        :key="stat.key"
        :title="stat.title"
        :value="stat.value"
        :unit="s__('Units|sec')"
      />
    </div>
  </div>
</template>
