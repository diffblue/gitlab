<script>
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import { formatNumber } from '~/locale';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { getAdoptedCountsByCols } from '../utils/helpers';
import {
  DEVOPS_ADOPTION_TABLE_CONFIGURATION,
  I18N_OVERVIEW_CHART_TITLE,
  I18N_OVERVIEW_CHART_Y_AXIS_TITLE,
  OVERVIEW_CHART_X_AXIS_TYPE,
  OVERVIEW_CHART_Y_AXIS_TYPE,
  OVERVIEW_CHART_PRESENTATION,
  I18N_NO_FEATURE_META,
  CUSTOM_PALETTE,
} from '../constants';
import devopsAdoptionOverviewChartQuery from '../graphql/queries/devops_adoption_overview_chart.query.graphql';
import DevopsAdoptionTableCellFlag from './devops_adoption_table_cell_flag.vue';

export default {
  components: {
    ChartSkeletonLoader,
    GlStackedColumnChart,
    DevopsAdoptionTableCellFlag,
  },
  i18n: {
    chartTitle: I18N_OVERVIEW_CHART_TITLE,
    noFeaturesTracked: I18N_NO_FEATURE_META,
  },
  presentation: OVERVIEW_CHART_PRESENTATION,
  inject: {
    groupGid: {
      default: null,
    },
  },
  customPalette: CUSTOM_PALETTE,
  data() {
    return {
      chartInstance: null,
      devopsAdoptionEnabledNamespaces: null,
      tooltipTitle: '',
      tooltipContentData: [],
    };
  },
  apollo: {
    devopsAdoptionEnabledNamespaces: {
      query: devopsAdoptionOverviewChartQuery,
      variables() {
        return {
          displayNamespaceId: this.groupGid ? this.groupGid : null,
          startDate: this.getMonthAgo(13),
          endDate: this.getMonthAgo(0),
        };
      },
      context: {
        isSingleRequest: true,
      },
    },
  },
  computed: {
    chartOptions() {
      return {
        xAxisTitle: '',
        yAxisTitle: I18N_OVERVIEW_CHART_Y_AXIS_TITLE,
        xAxisType: OVERVIEW_CHART_X_AXIS_TYPE,
        yAxis: [
          {
            minInterval: 1,
            type: OVERVIEW_CHART_Y_AXIS_TYPE,
            axisLabel: {
              formatter: (value) => formatNumber(value),
            },
          },
        ],
      };
    },
    sortedNodes() {
      const correctNode = this.devopsAdoptionEnabledNamespaces?.nodes.find(
        (node) => node.namespace?.id === this.groupGid,
      );

      return [...correctNode.snapshots.nodes].reverse();
    },
    groupBy() {
      return this.sortedNodes.map((snapshot) => dateFormat(snapshot.endTime, dateFormats.month));
    },
    chartData() {
      if (!this.devopsAdoptionEnabledNamespaces) return [];

      return DEVOPS_ADOPTION_TABLE_CONFIGURATION.map((section) => {
        const { cols } = section;

        return {
          name: section.title,
          data: getAdoptedCountsByCols(this.sortedNodes, cols),
        };
      });
    },
  },
  methods: {
    getMonthAgo(ago) {
      const date = new Date();
      date.setMonth(date.getMonth() - ago);

      return dateFormat(date.setDate(1), dateFormats.isoDate);
    },
    formatTooltipText(params) {
      const { value, seriesData } = params;
      const { dataIndex } = seriesData[0];
      const currentNode = this.sortedNodes[dataIndex];

      this.tooltipTitle = value;
      this.tooltipContentData = DEVOPS_ADOPTION_TABLE_CONFIGURATION.map((item) => ({
        ...item,
        featureMeta: item.cols.map((feature) => ({
          title: feature.label,
          adopted: Boolean(currentNode[feature.key]) || false,
          tracked: currentNode[feature.key] !== null,
        })),
      }));
    },
    hasFeaturesAvailable(section) {
      return section.featureMeta.some((feature) => feature.tracked);
    },
    lastItemInList(index, listLength) {
      return index === listLength - 1;
    },
    onChartCreated(chartInstance) {
      this.chartInstance = chartInstance;
    },
  },
};
</script>
<template>
  <div>
    <h4>{{ $options.i18n.chartTitle }}</h4>

    <gl-stacked-column-chart
      v-if="!$apollo.queries.devopsAdoptionEnabledNamespaces.loading"
      :responsive="true"
      :bars="chartData"
      :presentation="$options.presentation"
      :option="chartOptions"
      :x-axis-title="chartOptions.xAxisTitle"
      :y-axis-title="chartOptions.yAxisTitle"
      :x-axis-type="chartOptions.xAxisType"
      :group-by="groupBy"
      :format-tooltip-text="formatTooltipText"
      :custom-palette="$options.customPalette"
      @created="onChartCreated"
    >
      <template #tooltip-title>
        {{ tooltipTitle }}
      </template>
      <template #tooltip-content>
        <div
          v-for="(section, index) in tooltipContentData"
          :key="section.title"
          :class="{ 'gl-mb-3': !lastItemInList(index, tooltipContentData.length) }"
        >
          <div class="gl-font-weight-bold">{{ section.title }}</div>
          <template v-if="hasFeaturesAvailable(section)">
            <div v-for="feature in section.featureMeta" :key="feature.title">
              <template v-if="feature.tracked">
                <devops-adoption-table-cell-flag
                  :enabled="feature.adopted"
                  :variant="section.variant"
                  class="gl-mr-3"
                />
                {{ feature.title }}
              </template>
            </div>
          </template>
          <template v-else>
            {{ $options.i18n.noFeaturesTracked }}
          </template>
        </div>
      </template>
    </gl-stacked-column-chart>
    <chart-skeleton-loader v-else class="gl-mb-8" />
  </div>
</template>
