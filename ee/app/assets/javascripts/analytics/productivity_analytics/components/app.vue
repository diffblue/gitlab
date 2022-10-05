<script>
import {
  GlEmptyState,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownItem,
  GlButton,
  GlTooltipDirective,
  GlIcon,
  GlAlert,
} from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { mapState, mapActions, mapGetters } from 'vuex';
import { dateFormats } from '~/analytics/shared/constants';
import { getDataZoomOption } from '~/analytics/shared/utils';
import dateFormat from '~/lib/dateformat';
import { beginOfDayTime, endOfDayTime } from '~/lib/utils/datetime_utility';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import featureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Scatterplot from '../../shared/components/scatterplot.vue';
import {
  chartKeys,
  defaultMaxColumnChartItemsPerPage,
  maxColumnChartItemsPerPage,
} from '../constants';
import MetricChart from './metric_chart.vue';
import MergeRequestTable from './mr_table.vue';

export default {
  components: {
    GlEmptyState,
    GlLoadingIcon,
    GlDropdown,
    GlDropdownItem,
    GlColumnChart,
    GlButton,
    GlIcon,
    GlAlert,
    MetricChart,
    Scatterplot,
    MergeRequestTable,
    UrlSync,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [featureFlagsMixin()],
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    noAccessSvgPath: {
      type: String,
      required: true,
    },
    hideGroupDropDown: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      chartKeys,
    };
  },
  computed: {
    ...mapState('filters', [
      'groupNamespace',
      'projectPath',
      'authorUsername',
      'labelName',
      'milestoneTitle',
      'startDate',
      'endDate',
      'notMilestoneTitle',
      'notAuthorUsername',
      'notLabelName',
    ]),
    ...mapState('table', ['isLoadingTable', 'mergeRequests', 'pageInfo', 'columnMetric']),
    ...mapGetters(['getMetricTypes']),
    ...mapGetters('charts', [
      'chartLoading',
      'chartErrorCode',
      'chartHasData',
      'getColumnChartData',
      'getScatterPlotMainData',
      'getScatterPlotMedianData',
      'getMetricLabel',
      'getSelectedMetric',
      'scatterplotYaxisLabel',
      'hasNoAccessError',
      'isChartEnabled',
      'isFilteringByDaysToMerge',
    ]),
    ...mapGetters('table', [
      'sortFieldDropdownLabel',
      'sortIcon',
      'sortTooltipTitle',
      'tableSortOptions',
      'columnMetricLabel',
      'isSelectedSortField',
    ]),
    showAppContent() {
      return this.groupNamespace && !this.hasNoAccessError;
    },
    showMergeRequestTable() {
      return !this.isLoadingTable && this.mergeRequests.length;
    },
    showMergeRequestTableNoData() {
      return !this.isLoadingTable && !this.mergeRequests.length;
    },
    showSecondaryCharts() {
      return !this.chartLoading(chartKeys.main) && this.chartHasData(chartKeys.main);
    },
    query() {
      return {
        group_id: !this.hideGroupDropDown ? this.groupNamespace : null,
        project_id: this.projectPath,
        author_username: this.authorUsername,
        'label_name[]': this.labelName,
        milestone_title: this.milestoneTitle,
        merged_after: `${dateFormat(this.startDate, dateFormats.isoDate)}${beginOfDayTime}`,
        merged_before: `${dateFormat(this.endDate, dateFormats.isoDate)}${endOfDayTime}`,
        'not[author_username]': this.notAuthorUsername,
        'not[milestone_title]': this.notMilestoneTitle,
        'not[label_name][]': this.notLabelName,
      };
    },
  },
  methods: {
    ...mapActions('charts', [
      'fetchChartData',
      'setMetricType',
      'updateSelectedItems',
      'resetMainChartSelection',
    ]),
    ...mapActions('table', ['setSortField', 'setPage', 'toggleSortOrder', 'setColumnMetric']),
    onMainChartItemClicked({ params }) {
      const itemValue = params.data.value[0];
      this.updateSelectedItems({ chartKey: this.chartKeys.main, item: itemValue });
    },
    getColumnChartOption(chartKey) {
      const totalItems = this.getColumnChartData(chartKey).length;
      const maxItemsPerPage = maxColumnChartItemsPerPage[chartKey]
        ? maxColumnChartItemsPerPage[chartKey]
        : defaultMaxColumnChartItemsPerPage;
      return {
        yAxis: {
          axisLabel: {
            formatter: (value) => value,
          },
          minInterval: 1,
        },
        ...getDataZoomOption({ totalItems, maxItemsPerPage }),
      };
    },
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="!groupNamespace"
      class="js-empty-state"
      :title="
        __('Productivity analytics can help identify the problems that are delaying your team')
      "
      :svg-path="emptyStateSvgPath"
      :description="
        __(
          'Start by choosing a group to start exploring the merge requests in that group. You can then proceed to filter by projects, labels, milestones and authors.',
        )
      "
    />
    <gl-empty-state
      v-if="hasNoAccessError"
      class="js-empty-state"
      :title="__('You don’t have access to Productivity Analytics in this group')"
      :svg-path="noAccessSvgPath"
      :description="
        __(
          'Only ‘Reporter’ roles and above on tiers Premium and above can see Productivity Analytics.',
        )
      "
    />
    <template v-if="showAppContent">
      <div class="d-flex justify-content-between">
        <h4>{{ s__('ProductivityAnalytics|Merge Requests') }}</h4>
        <gl-button
          v-if="isFilteringByDaysToMerge"
          ref="clearChartFiltersBtn"
          class="btn-link float-right"
          type="button"
          variant="default"
          @click="resetMainChartSelection()"
          >{{ __('Clear chart filters') }}</gl-button
        >
      </div>
      <metric-chart
        ref="mainChart"
        class="mb-4"
        :title="s__('ProductivityAnalytics|Time to merge')"
        :description="
          __('You can filter by \'days to merge\' by clicking on the columns in the chart.')
        "
        :is-loading="chartLoading(chartKeys.main)"
        :error-code="chartErrorCode(chartKeys.main)"
        :chart-data="getColumnChartData(chartKeys.main)"
      >
        <gl-column-chart
          :bars="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
            { name: 'full', data: getColumnChartData(chartKeys.main) },
          ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
          :option="getColumnChartOption(chartKeys.main)"
          :y-axis-title="__('Merge requests')"
          :x-axis-title="__('Days')"
          x-axis-type="category"
          @chartItemClicked="onMainChartItemClicked"
        />
      </metric-chart>

      <template v-if="showSecondaryCharts">
        <div ref="secondaryCharts">
          <metric-chart
            v-if="isChartEnabled(chartKeys.scatterplot)"
            ref="scatterplot"
            class="mb-4"
            :title="s__('ProductivityAnalytics|Trendline')"
            :is-loading="chartLoading(chartKeys.scatterplot)"
            :metric-types="getMetricTypes(chartKeys.scatterplot)"
            :chart-data="getScatterPlotMainData"
            :selected-metric="getSelectedMetric(chartKeys.scatterplot)"
            @metricTypeChange="
              (metric) => setMetricType({ metricType: metric, chartKey: chartKeys.scatterplot })
            "
          >
            <scatterplot
              :x-axis-title="s__('ProductivityAnalytics|Merge date')"
              :y-axis-title="scatterplotYaxisLabel"
              :scatter-data="getScatterPlotMainData"
              :median-line-data="getScatterPlotMedianData"
            />
          </metric-chart>

          <div class="row">
            <metric-chart
              ref="timeBasedChart"
              class="col-lg-6 col-sm-12 mb-4"
              :description="
                __(
                  'Not all data has been processed yet, the accuracy of the chart for the selected timeframe is limited.',
                )
              "
              :is-loading="chartLoading(chartKeys.timeBasedHistogram)"
              :metric-types="getMetricTypes(chartKeys.timeBasedHistogram)"
              :selected-metric="getSelectedMetric(chartKeys.timeBasedHistogram)"
              :chart-data="getColumnChartData(chartKeys.timeBasedHistogram)"
              @metricTypeChange="
                (metric) =>
                  setMetricType({ metricType: metric, chartKey: chartKeys.timeBasedHistogram })
              "
            >
              <gl-column-chart
                :bars="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
                  { name: 'full', data: getColumnChartData(chartKeys.timeBasedHistogram) },
                ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
                :option="getColumnChartOption(chartKeys.timeBasedHistogram)"
                :y-axis-title="s__('ProductivityAnalytics|Merge requests')"
                :x-axis-title="s__('ProductivityAnalytics|Hours')"
                x-axis-type="category"
              />
            </metric-chart>

            <metric-chart
              ref="commitBasedChart"
              class="col-lg-6 col-sm-12 mb-4"
              :description="
                __(
                  'Not all data has been processed yet, the accuracy of the chart for the selected timeframe is limited.',
                )
              "
              :is-loading="chartLoading(chartKeys.commitBasedHistogram)"
              :metric-types="getMetricTypes(chartKeys.commitBasedHistogram)"
              :selected-metric="getSelectedMetric(chartKeys.commitBasedHistogram)"
              :chart-data="getColumnChartData(chartKeys.commitBasedHistogram)"
              @metricTypeChange="
                (metric) =>
                  setMetricType({ metricType: metric, chartKey: chartKeys.commitBasedHistogram })
              "
            >
              <gl-column-chart
                :bars="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
                  { name: 'full', data: getColumnChartData(chartKeys.commitBasedHistogram) },
                ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
                :option="getColumnChartOption(chartKeys.commitBasedHistogram)"
                :y-axis-title="s__('ProductivityAanalytics|Merge requests')"
                :x-axis-title="getMetricLabel(chartKeys.commitBasedHistogram)"
                x-axis-type="category"
              />
            </metric-chart>
          </div>

          <div
            class="js-mr-table-sort d-flex flex-column flex-md-row align-items-md-center justify-content-between mb-2"
          >
            <h5>{{ s__('ProductivityAnalytics|List') }}</h5>
            <div
              v-if="showMergeRequestTable"
              class="d-flex flex-column flex-md-row align-items-md-center"
            >
              <strong class="gl-mr-3">{{ __('Sort by') }}</strong>
              <div class="d-flex">
                <gl-dropdown
                  class="gl-mr-3 flex-grow"
                  toggle-class="dropdown-menu-toggle"
                  :text="sortFieldDropdownLabel"
                >
                  <gl-dropdown-item
                    v-for="metric in tableSortOptions"
                    :key="metric.key"
                    active-class="is-active"
                    class="w-100"
                    @click="setSortField(metric.key)"
                  >
                    <span class="d-flex">
                      <gl-icon
                        class="flex-shrink-0 gl-mr-2"
                        :class="{
                          invisible: !isSelectedSortField(metric.key),
                        }"
                        name="mobile-issue-close"
                      />
                      {{ metric.label }}
                    </span>
                  </gl-dropdown-item>
                </gl-dropdown>
                <gl-button
                  v-gl-tooltip.hover
                  :title="sortTooltipTitle"
                  :aria-label="sortTooltipTitle"
                  @click="toggleSortOrder"
                >
                  <gl-icon :name="sortIcon" />
                </gl-button>
              </div>
            </div>
          </div>
        </div>

        <div class="js-mr-table">
          <gl-loading-icon v-if="isLoadingTable" size="lg" class="my-4 py-4" />
          <merge-request-table
            v-if="showMergeRequestTable"
            :merge-requests="mergeRequests"
            :page-info="pageInfo"
            :column-options="getMetricTypes(chartKeys.timeBasedHistogram)"
            :metric-type="columnMetric"
            :metric-label="columnMetricLabel"
            @columnMetricChange="setColumnMetric"
            @pageChange="setPage"
          />
          <gl-alert v-if="showMergeRequestTableNoData" variant="info" :dismissible="false">
            {{ __('There is no data available. Please change your selection.') }}
          </gl-alert>
        </div>
      </template>
    </template>
    <url-sync :query="query" url-params-update-strategy="set" />
  </div>
</template>
