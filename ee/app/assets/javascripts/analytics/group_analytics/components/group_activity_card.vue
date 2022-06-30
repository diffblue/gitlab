<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import Api from 'ee/api';
import createFlash from '~/flash';
import { __, s__ } from '~/locale';

export default {
  name: 'GroupActivityCard',
  components: {
    GlSkeletonLoader,
    GlSingleStat,
  },
  inject: ['groupFullPath', 'groupName'],
  data() {
    return {
      isLoading: false,
      metrics: {
        mergeRequests: {
          value: null,
          label: s__('GroupActivityMetrics|Merge Requests created'),
        },
        issues: { value: null, label: s__('GroupActivityMetrics|Issues created') },
        newMembers: { value: null, label: s__('GroupActivityMetrics|Members added') },
      },
    };
  },
  computed: {
    metricsArray() {
      return Object.entries(this.metrics).map(([key, obj]) => {
        const { value, label } = obj;
        return {
          key,
          value,
          label,
        };
      });
    },
  },
  created() {
    this.fetchMetrics(this.groupFullPath);
  },
  methods: {
    fetchMetrics(groupPath) {
      this.isLoading = true;

      return Promise.all([
        Api.groupActivityMergeRequestsCount(groupPath),
        Api.groupActivityIssuesCount(groupPath),
        Api.groupActivityNewMembersCount(groupPath),
      ])
        .then(([mrResponse, issuesResponse, newMembersResponse]) => {
          this.metrics.mergeRequests.value = mrResponse.data.merge_requests_count;
          this.metrics.issues.value = issuesResponse.data.issues_count;
          this.metrics.newMembers.value = newMembersResponse.data.new_members_count;
          this.isLoading = false;
        })
        .catch(() => {
          createFlash({
            message: __('Failed to load group activity metrics. Please try again.'),
          });
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-mt-6 gl-mb-4 gl-align-items-flex-start"
  >
    <div class="gl-display-flex gl-flex-direction-column gl-pr-9 gl-flex-shrink-0">
      <span class="gl-font-weight-bold">{{ s__('GroupActivityMetrics|Recent activity') }}</span>
      <span>{{ s__('GroupActivityMetrics|Last 30 days') }}</span>
    </div>
    <div
      v-for="metric in metricsArray"
      :key="metric.key"
      class="gl-pr-9 gl-my-4 gl-md-mt-0 gl-md-mb-0"
    >
      <gl-skeleton-loader v-if="isLoading" />
      <gl-single-stat
        v-else
        :value="`${metric.value}`"
        :title="metric.label"
        :should-animate="true"
      />
    </div>
  </div>
</template>
