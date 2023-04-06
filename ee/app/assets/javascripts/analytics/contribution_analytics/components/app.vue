<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import {
  filterIssues,
  filterMergeRequests,
  filterPushes,
  mergeContributions,
  restrictRequestEndDate,
} from '../utils';
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
      isLoading: false,
    };
  },
  computed: {
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
  async created() {
    await this.fetchContributions(this.startDate);
  },
  methods: {
    async fetchContributions(startDate, nextPageCursor = '') {
      this.isLoading = true;

      try {
        const { endDate, nextStartDate } = restrictRequestEndDate(startDate, this.endDate);

        const { data } = await this.$apollo.query({
          query: contributionsQuery,
          variables: {
            fullPath: this.fullPath,
            startDate,
            endDate,
            nextPageCursor,
          },
        });

        const { nodes = [], pageInfo } = data.group?.contributions || {};
        this.contributions = mergeContributions(this.contributions, nodes);

        if (pageInfo?.hasNextPage) {
          await this.fetchContributions(startDate, pageInfo.endCursor);
        } else if (nextStartDate !== null) {
          await this.fetchContributions(nextStartDate);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.loadError = true;
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" :label="$options.i18n.loading" size="lg" />

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
