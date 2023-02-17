<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import { filterIssues, filterMergeRequests, filterPushes } from '../utils';
import contributionsQuery from '../graphql/contributions.query.graphql';
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
    GlLoadingIcon,
    GlAlert,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    startDate: {
      type: String,
      required: true,
    },
    endDate: {
      type: String,
      required: true,
    },
  },
  i18n: {
    loading: s__('ContributionAnalytics|Loading contribution stats for group members'),
    error: s__('ContributionAnalytics|Failed to load the contribution stats'),
  },
  data() {
    return {
      contributions: [],
      loadError: false,
    };
  },
  apollo: {
    // TODO: This query should paginate until there are no results.
    // Currently it only loads the first 100 users due to GraphQL limits.
    contributions: {
      query: contributionsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          startDate: this.startDate,
          endDate: this.endDate,
        };
      },
      update(data) {
        return data.group?.contributions.nodes || [];
      },
      error() {
        this.loadError = true;
      },
    },
  },
  computed: {
    loading() {
      return Boolean(this.$apollo.queries.contributions?.loading);
    },
    pushes() {
      return filterPushes(this.contributions);
    },
    mergeRequests() {
      return filterMergeRequests(this.contributions);
    },
    issues() {
      return filterIssues(this.contributions);
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="loading" :label="$options.i18n.loading" size="lg" />

    <gl-alert v-else-if="loadError" variant="danger" :dismissible="false">
      {{ $options.i18n.error }}
    </gl-alert>

    <template v-else>
      <pushes-chart :pushes="pushes" />
      <merge-requests-chart :merge-requests="mergeRequests" />
      <issues-chart :issues="issues" />
      <group-members-table :contributions="contributions" />
    </template>
  </div>
</template>
