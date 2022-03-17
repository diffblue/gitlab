<script>
import { GlIcon, GlPopover } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { formatDate } from '~/lib/utils/datetime_utility';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { s__, __ } from '~/locale';
import getCiMinutesUsageByNamespace from '../graphql/ci_minutes.query.graphql';

export default {
  components: {
    GlIcon,
    GlPopover,
    GlAreaChart,
  },
  i18n: {
    sharedRunnersUsage: s__('CICDAnalytics|Shared Runners Usage'),
    xAxisLabel: __('Month'),
    yAxisLabel: __('Minutes'),
    seriesName: s__('CICDAnalytics|Shared runner pipeline minute duration by month'),
  },
  popoverOptions: {
    triggers: 'hover',
    placement: 'top',
    content: s__(
      'CICDAnalytics|Shared runner usage is the total runtime of all jobs that ran on shared runners',
    ),
    title: s__('CICDAnalytics|What is shared runner usage?'),
  },
  inject: ['groupId'],
  data() {
    return {
      ciMinutesUsage: [],
    };
  },
  apollo: {
    ciMinutesUsage: {
      query: getCiMinutesUsageByNamespace,
      variables() {
        return {
          namespaceId: convertToGraphQLId(TYPE_GROUP, this.groupId),
        };
      },
      update(res) {
        return res?.ciMinutesUsage?.nodes;
      },
    },
  },
  computed: {
    chartOptions() {
      return {
        xAxis: {
          name: this.$options.i18n.xAxisLabel,
          type: 'category',
        },
        yAxis: {
          name: this.$options.i18n.yAxisLabel,
        },
      };
    },
    minutesUsageDataByMonth() {
      return this.ciMinutesUsage
        .slice()
        .sort((a, b) => {
          return new Date(a.monthIso8601) - new Date(b.monthIso8601);
        })
        .map((cur) => [formatDate(cur.monthIso8601, 'mmm yyyy'), cur.sharedRunnersDuration]);
    },
    isDataEmpty() {
      return this.minutesUsageDataByMonth.length === 0;
    },
    chartData() {
      return [
        {
          data: this.minutesUsageDataByMonth,
          name: this.$options.i18n.seriesName,
        },
      ];
    },
  },
};
</script>
<template>
  <div class="gl-mt-4">
    <div class="gl-display-flex gl-align-items-center gl-mb-4">
      <div class="gl-display-flex">
        <h3 class="gl-mr-2 gl-my-0">{{ $options.i18n.sharedRunnersUsage }}</h3>
      </div>
      <div id="shared-runner-message-popover-container" class="gl-display-flex">
        <span id="shared-runner-question">
          <gl-icon class="gl-text-blue-500" name="question-o" />
        </span>
        <gl-popover
          target="shared-runner-question"
          container="shared-runner-message-popover-container"
          v-bind="$options.popoverOptions"
        />
      </div>
    </div>
    <gl-area-chart
      v-if="!isDataEmpty"
      :data="chartData"
      :option="chartOptions"
      :width="0"
      responsive
    />
  </div>
</template>
