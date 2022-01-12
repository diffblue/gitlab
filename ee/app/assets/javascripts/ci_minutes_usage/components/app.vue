<script>
import { formatDate } from '~/lib/utils/datetime_utility';
import getCiMinutesUsage from '../graphql/queries/ci_minutes.graphql';
import MinutesUsageMonthChart from './minutes_usage_month_chart.vue';
import MinutesUsageProjectChart from './minutes_usage_project_chart.vue';

export default {
  components: {
    MinutesUsageMonthChart,
    MinutesUsageProjectChart,
  },
  data() {
    return {
      ciMinutesUsage: [],
    };
  },
  apollo: {
    ciMinutesUsage: {
      query: getCiMinutesUsage,
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
  },
};
</script>
<template>
  <div class="gl-border-b-solid gl-border-gray-200 gl-border-b-1 gl-mb-3">
    <minutes-usage-month-chart
      class="gl-border-b-solid gl-border-gray-200 gl-border-b-1"
      :minutes-usage-data="minutesUsageDataByMonth"
    />
    <minutes-usage-project-chart :minutes-usage-data="ciMinutesUsage" />
  </div>
</template>
