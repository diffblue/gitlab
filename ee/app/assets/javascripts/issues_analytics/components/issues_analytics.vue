<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { nMonthsBefore, getStartOfDay, dateAtFirstDayOfMonth } from '~/lib/utils/datetime_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import FilteredSearchIssueAnalytics from '../filtered_search_issues_analytics';
import { DEFAULT_MONTHS_BACK } from '../constants';
import { transformFilters } from '../utils';
import IssuesAnalyticsTable from './issues_analytics_table.vue';
import IssuesAnalyticsChart from './issues_analytics_chart.vue';
import TotalIssuesAnalyticsChart from './total_issues_analytics_chart.vue';

export default {
  components: {
    IssuesAnalyticsTable,
    IssuesAnalyticsChart,
    TotalIssuesAnalyticsChart,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    hasIssuesCompletedFeature: {
      default: false,
    },
  },
  props: {
    filterBlockEl: {
      type: HTMLDivElement,
      required: true,
    },
  },
  computed: {
    ...mapGetters('issueAnalytics', ['appliedFilters']),
    supportsIssuesCompletedAnalytics() {
      return this.hasIssuesCompletedFeature && this.glFeatures?.issuesCompletedAnalyticsFeatureFlag;
    },
    monthsBack() {
      const { monthsBack } = this.filters ?? {};

      return monthsBack ?? DEFAULT_MONTHS_BACK;
    },
    startDate() {
      return nMonthsBefore(this.endDate, Number(this.monthsBack), { utc: true });
    },
    endDate() {
      const now = new Date();

      return getStartOfDay(dateAtFirstDayOfMonth(now), { utc: true });
    },
    filters() {
      return transformFilters(this.appliedFilters);
    },
  },
  created() {
    const { hasIssuesCompletedFeature } = this;

    this.filterManager = new FilteredSearchIssueAnalytics({
      hasIssuesCompletedFeature,
      ...this.appliedFilters,
    });
    this.filterManager.setup();
  },
  methods: {
    hideFilteredSearchBar() {
      this.filterBlockEl.classList.add('hide');
    },
  },
};
</script>
<template>
  <div class="issues-analytics-wrapper">
    <total-issues-analytics-chart
      v-if="supportsIssuesCompletedAnalytics"
      :start-date="startDate"
      :end-date="endDate"
      :filters="filters"
      class="gl-mt-6"
      @hideFilteredSearchBar="hideFilteredSearchBar"
    />
    <issues-analytics-chart v-else @hasNoData="hideFilteredSearchBar" />
    <issues-analytics-table class="gl-mt-6" />
  </div>
</template>
