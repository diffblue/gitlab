<script>
import PushesChart from './pushes_chart.vue';
import MergeRequestsChart from './merge_requests_chart.vue';
import IssuesChart from './issues_chart.vue';

export default {
  name: 'ContributionAnalyticsApp',
  components: {
    PushesChart,
    MergeRequestsChart,
    IssuesChart,
  },
};
</script>
<template>
  <div>
    <pushes-chart />
    <merge-requests-chart />
    <issues-chart />
  </div>
</template>
