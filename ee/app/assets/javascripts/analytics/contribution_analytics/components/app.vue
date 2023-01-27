<script>
import PushesChart from './pushes_chart.vue';
import MergeRequestsChart from './merge_requests_chart.vue';
import IssuesChart from './issues_chart.vue';
import GroupMembersTable from './group_members_table.vue';

export default {
  name: 'ContributionAnalyticsApp',
  components: {
    PushesChart,
    MergeRequestsChart,
    IssuesChart,
    GroupMembersTable,
  },
};
</script>
<template>
  <div>
    <pushes-chart />
    <merge-requests-chart />
    <issues-chart />
    <group-members-table />
  </div>
</template>
