<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
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
      return this.contributions
        .filter(({ repoPushed }) => repoPushed > 0)
        .map(({ repoPushed: count, user: { name: user } }) => ({ count, user }));
    },
    mergeRequests() {
      return this.contributions
        .filter(
          ({
            mergeRequestsClosed: closed,
            mergeRequestsCreated: created,
            mergeRequestsMerged: merged,
          }) => closed + created + merged > 0,
        )
        .map(
          ({
            mergeRequestsClosed: closed,
            mergeRequestsCreated: created,
            mergeRequestsMerged: merged,
            user: { name: user },
          }) => ({ closed, created, merged, user }),
        );
    },
    issues() {
      return this.contributions
        .filter(({ issuesClosed: closed, issuesCreated: created }) => closed + created > 0)
        .map(({ issuesClosed: closed, issuesCreated: created, user: { name: user } }) => ({
          closed,
          created,
          user,
        }));
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
