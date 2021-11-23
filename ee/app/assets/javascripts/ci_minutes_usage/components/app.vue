<script>
import { MONTHS } from '../constants';
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
      function monthIndex([name]) {
        return Object.keys(MONTHS).indexOf(name.toLowerCase());
      }

      return this.ciMinutesUsage
        .map((cur) => [cur.month, cur.minutes])
        .sort((a, b) => {
          if (monthIndex(a) > monthIndex(b)) {
            return 1;
          }
          if (monthIndex(a) < monthIndex(b)) {
            return -1;
          }
          return 0;
        });
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
