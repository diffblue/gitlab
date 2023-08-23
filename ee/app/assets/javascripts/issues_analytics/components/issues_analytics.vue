<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import FilteredSearchIssueAnalytics from '../filtered_search_issues_analytics';
import IssuesAnalyticsTable from './issues_analytics_table.vue';
import IssuesAnalyticsChart from './issues_analytics_chart.vue';

export default {
  components: {
    IssuesAnalyticsTable,
    IssuesAnalyticsChart,
  },
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
    issuesTableEndpoints() {
      return {
        issuesPage: this.issuesPageEndpoint,
      };
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
    <issues-analytics-chart @hasNoData="hideFilteredSearchBar" />
    <issues-analytics-table class="mt-8" />
  </div>
</template>
