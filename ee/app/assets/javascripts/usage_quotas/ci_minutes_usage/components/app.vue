<script>
import { formatDate } from '~/lib/utils/datetime_utility';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import MinutesUsageMonthChart from 'ee/ci_minutes_usage/components/minutes_usage_month_chart.vue';
import MinutesUsageProjectChart from 'ee/ci_minutes_usage/components/minutes_usage_project_chart.vue';
import getCiMinutesUsageGroup from '../graphql/queries/ci_minutes_namespace.query.graphql';

export default {
  components: {
    MinutesUsageMonthChart,
    MinutesUsageProjectChart,
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
    minutesUsageDataByMonth() {
      return this.ciMinutesUsage
        .slice()
        .sort((a, b) => {
          return new Date(a.monthIso8601) - new Date(b.monthIso8601);
        })
        .map((cur) => [formatDate(cur.monthIso8601, 'mmm yyyy'), cur.minutes]);
    },
    borderStyles() {
      return 'gl-border-b-solid gl-border-gray-200 gl-border-b-1';
    },
  },
};
</script>
<template>
  <div :class="borderStyles" class="gl-my-7">
    <minutes-usage-month-chart
      :class="borderStyles"
      :minutes-usage-data="minutesUsageDataByMonth"
    />
    <minutes-usage-project-chart :minutes-usage-data="ciMinutesUsage" />
  </div>
</template>
