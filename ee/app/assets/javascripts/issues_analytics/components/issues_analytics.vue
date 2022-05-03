<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { GlColumnChart, GlChartLegend } from '@gitlab/ui/dist/charts';
import { engineeringNotation, sum, average } from '@gitlab/ui/src/utils/number_utils';
import { mapGetters, mapActions, mapState } from 'vuex';
import { getMonthNames } from '~/lib/utils/datetime_utility';
import { getSvgIconPathContent } from '~/lib/utils/icon_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import FilteredSearchIssueAnalytics from '../filtered_search_issues_analytics';
import { transformFilters } from '../utils';
import IssuesAnalyticsTable from './issues_analytics_table.vue';

export default {
  components: {
    GlLoadingIcon,
    GlEmptyState,
    GlColumnChart,
    GlChartLegend,
    IssuesAnalyticsTable,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    issuesApiEndpoint: {
      type: String,
      required: true,
    },
    issuesPageEndpoint: {
      type: String,
      required: true,
    },
    filterBlockEl: {
      type: HTMLDivElement,
      required: true,
    },
    noDataEmptyStateSvgPath: {
      type: String,
      required: true,
    },
    filtersEmptyStateSvgPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      svgs: {},
      chart: null,
      seriesInfo: [
        {
          type: 'solid',
          name: s__('IssuesAnalytics|Issues created'),
          color: '#1F78D1',
        },
      ],
    };
  },
  computed: {
    ...mapState('issueAnalytics', ['chartData', 'loading']),
    ...mapGetters('issueAnalytics', ['hasFilters', 'appliedFilters']),
    data() {
      const { chartData, chartHasData } = this;
      const data = [];

      if (chartHasData()) {
        Object.keys(chartData).forEach((key) => {
          const date = new Date(key);
          const label = `${getMonthNames(true)[date.getUTCMonth()]} ${date.getUTCFullYear()}`;
          const val = chartData[key];

          data.push([label, val]);
        });
      }

      return data;
    },
    chartLabels() {
      return this.data.map((val) => val[0]);
    },
    chartDateRange() {
      return `${this.chartLabels[0]} - ${this.chartLabels[this.chartLabels.length - 1]}`;
    },
    showChart() {
      return !this.loading && this.chartHasData();
    },
    showNoDataEmptyState() {
      return !this.loading && !this.showChart && !this.hasFilters;
    },
    showFiltersEmptyState() {
      return !this.loading && !this.showChart && this.hasFilters;
    },
    dataZoomConfig() {
      const config = {
        type: 'slider',
        startValue: 0,
      };

      if (this.svgs['scroll-handle']) {
        return { ...config, handleIcon: this.svgs['scroll-handle'] };
      }

      return config;
    },
    chartOptions() {
      return {
        dataZoom: [this.dataZoomConfig],
      };
    },
    series() {
      return this.data.map((val) => val[1]);
    },
    seriesAverage() {
      return engineeringNotation(average(...this.series), 0);
    },
    seriesTotal() {
      return engineeringNotation(sum(...this.series));
    },
    issuesTableEndpoints() {
      const publicApiFilters = transformFilters(this.appliedFilters);

      return {
        api: mergeUrlParams(publicApiFilters, this.issuesApiEndpoint),
        issuesPage: this.issuesPageEndpoint,
      };
    },
    filterString() {
      return JSON.stringify(this.appliedFilters);
    },
  },
  watch: {
    appliedFilters() {
      this.fetchChartData(this.endpoint);
    },
    showNoDataEmptyState(showEmptyState) {
      if (showEmptyState) {
        this.$nextTick(() => this.filterBlockEl.classList.add('hide'));
      }
    },
  },
  created() {
    this.filterManager = new FilteredSearchIssueAnalytics(this.appliedFilters);
    this.filterManager.setup();

    this.setSvg('scroll-handle');
  },
  mounted() {
    this.fetchChartData(this.endpoint);
  },
  methods: {
    ...mapActions('issueAnalytics', ['fetchChartData']),
    onCreated(chart) {
      this.chart = chart;
    },
    chartHasData() {
      if (!this.chartData) {
        return false;
      }

      return Object.values(this.chartData).some((val) => val > 0);
    },
    setSvg(name) {
      getSvgIconPathContent(name)
        .then((path) => {
          if (path) {
            this.$set(this.svgs, name, `path://${path}`);
          }
        })
        .catch(() => {});
    },
  },
};
</script>
<template>
  <div class="issues-analytics-wrapper" data-qa-selector="issues_analytics_wrapper">
    <gl-loading-icon v-if="loading" size="lg" class="mt-8" />

    <div v-if="showChart" class="issues-analytics-chart">
      <h4 class="gl-mt-6 gl-mb-7">{{ s__('IssuesAnalytics|Issues created per month') }}</h4>

      <gl-column-chart
        data-qa-selector="issues_analytics_graph"
        :bars="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
          { name: 'Full', data },
        ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        :option="chartOptions"
        :y-axis-title="s__('IssuesAnalytics|Issues created')"
        :x-axis-title="s__('IssuesAnalytics|Last 12 months') + ' (' + chartDateRange + ')'"
        x-axis-type="category"
        @created="onCreated"
      />
      <div class="d-flex">
        <gl-chart-legend v-if="chart" :chart="chart" :series-info="seriesInfo" />
        <div class="gl-font-sm gl-text-gray-500">
          {{ s__('IssuesAnalytics|Total:') }} {{ seriesTotal }}
          &#8226;
          {{ s__('IssuesAnalytics|Avg/Month:') }} {{ seriesAverage }}
        </div>
      </div>
    </div>

    <issues-analytics-table :key="filterString" class="mt-8" :endpoints="issuesTableEndpoints" />

    <gl-empty-state
      v-if="showFiltersEmptyState"
      :title="s__('IssuesAnalytics|Sorry, your filter produced no results')"
      :description="
        s__(
          'IssuesAnalytics|To widen your search, change or remove filters in the filter bar above',
        )
      "
      :svg-path="filtersEmptyStateSvgPath"
    />

    <gl-empty-state
      v-if="showNoDataEmptyState"
      :title="s__('IssuesAnalytics|There are no issues for the projects in your group')"
      :description="
        s__(
          'IssuesAnalytics|After you begin creating issues for your projects, we can start tracking and displaying metrics for them',
        )
      "
      :svg-path="noDataEmptyStateSvgPath"
    />
  </div>
</template>
