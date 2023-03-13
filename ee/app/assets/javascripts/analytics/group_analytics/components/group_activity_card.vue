<script>
import { GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import Api from 'ee/api';
import { createAlert } from '~/alert';
import { sprintf, __, s__ } from '~/locale';
import Tracking from '~/tracking';

const MERGE_REQUESTS_TRACKING_LABEL = 'g_analytics_activity_widget_mr_created_clicked';
const ISSUES_TRACKING_LABEL = 'g_analytics_activity_widget_issues_created_clicked';
const NEW_MEMBERS_TRACKING_LABEL = 'g_analytics_activity_widget_members_added_clicked';
const ACTIVITY_COUNT_LIMIT = 999;

export default {
  name: 'GroupActivityCard',
  components: {
    GlSkeletonLoader,
    GlSingleStat,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['groupFullPath', 'groupName'],
  data() {
    return {
      isLoading: false,
      metrics: {
        mergeRequests: {
          value: null,
          label: s__('GroupActivityMetrics|Merge requests created'),
          link: `/groups/${this.groupFullPath}/-/analytics/productivity_analytics`,
          trackingLabel: MERGE_REQUESTS_TRACKING_LABEL,
        },
        issues: {
          value: null,
          label: s__('GroupActivityMetrics|Issues created'),
          link: `/groups/${this.groupFullPath}/-/issues_analytics`,
          trackingLabel: ISSUES_TRACKING_LABEL,
        },
        newMembers: {
          value: null,
          label: s__('GroupActivityMetrics|Members added'),
          link: `/groups/${this.groupFullPath}/-/group_members?sort=last_joined`,
          trackingLabel: NEW_MEMBERS_TRACKING_LABEL,
        },
      },
    };
  },
  computed: {
    metricsArray() {
      return Object.entries(this.metrics).map(([key, obj]) => {
        const { value, label, link, trackingLabel } = obj;
        return {
          key,
          value,
          label,
          link,
          trackingLabel,
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
          createAlert({
            message: __('Failed to load group activity metrics. Please try again.'),
          });
          this.isLoading = false;
        });
    },
    clampValue(value) {
      return value > ACTIVITY_COUNT_LIMIT ? '999+' : `${value}`;
    },
    tooltip(value) {
      return value > ACTIVITY_COUNT_LIMIT ? __('Results limit reached') : null;
    },
    clickMetric(trackingLabel) {
      this.track('click_button', { label: trackingLabel });
    },
  },
  activityTimeSpan: sprintf(__('Last %{days} days'), { days: 30 }),
};
</script>

<template>
  <div
    class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-mt-6 gl-mb-4 gl-align-items-flex-start"
  >
    <div class="gl-display-flex gl-flex-direction-column gl-pr-9 gl-flex-shrink-0">
      <span>{{ s__('GroupActivityMetrics|Recent activity') }}</span>
      <span class="gl-font-weight-bold">{{ $options.activityTimeSpan }}</span>
    </div>
    <div
      v-for="{ key, value, label, link, trackingLabel } in metricsArray"
      :key="key"
      class="gl-pr-9 gl-my-4 gl-md-mt-0 gl-md-mb-0"
    >
      <gl-skeleton-loader v-if="isLoading" />
      <a
        v-else
        :href="link"
        class="gl-display-block gl-text-decoration-none! gl-hover-bg-gray-50 gl-rounded-base"
        data-testid="single-stat-link"
        @click="clickMetric(trackingLabel)"
      >
        <gl-single-stat
          v-gl-tooltip="tooltip(value)"
          :value="clampValue(value)"
          :title="label"
          :should-animate="true"
        />
      </a>
    </div>
  </div>
</template>
