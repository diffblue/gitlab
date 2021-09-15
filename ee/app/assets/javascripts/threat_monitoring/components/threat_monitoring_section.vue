<script>
import { GlEmptyState } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { setUrlFragment } from '~/lib/utils/url_utility';
import LoadingSkeleton from './loading_skeleton.vue';

export default {
  components: {
    GlEmptyState,
    LoadingSkeleton,
    StatisticsSummary: () =>
      import(/* webpackChunkName: 'threat_statistics' */ './statistics_summary.vue'),
    StatisticsHistory: () =>
      import(/* webpackChunkName: 'threat_statistics' */ './statistics_history.vue'),
  },
  props: {
    storeNamespace: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    subtitle: {
      type: String,
      required: true,
    },
    nominalTitle: {
      type: String,
      required: true,
    },
    anomalousTitle: {
      type: String,
      required: true,
    },
    yLegend: {
      type: String,
      required: true,
    },
    chartEmptyStateTitle: {
      type: String,
      required: true,
    },
    chartEmptyStateText: {
      type: String,
      required: true,
    },
    chartEmptyStateSvgPath: {
      type: String,
      required: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
    documentationAnchor: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('threatMonitoring', ['currentEnvironmentId', 'currentTimeWindow']),
    ...mapState({
      isLoading(state) {
        return state[this.storeNamespace].isLoadingStatistics;
      },
      statistics(state) {
        return state[this.storeNamespace].statistics;
      },
      hasHistory(state, getters) {
        return getters[`${this.storeNamespace}/hasHistory`];
      },
      timeRange(state) {
        return state[this.storeNamespace].timeRange;
      },
    }),
    summary() {
      const { anomalous, total } = this.statistics;
      return {
        anomalous: { title: this.anomalousTitle, value: anomalous },
        nominal: { title: this.nominalTitle, value: total },
      };
    },
    chart() {
      if (!this.hasHistory) return {};

      const { anomalous, nominal } = this.statistics.history;
      return {
        anomalous: { title: this.anomalousTitle, values: anomalous },
        nominal: { title: this.nominalTitle, values: nominal },
        from: this.timeRange.from,
        to: this.timeRange.to,
      };
    },
    documentationFullPath() {
      return setUrlFragment(this.documentationPath, this.documentationAnchor);
    },
  },
  watch: {
    currentEnvironmentId() {
      this.fetchStatistics();
    },
    currentTimeWindow() {
      this.fetchStatistics();
    },
  },
  created() {
    this.fetchStatistics();
  },
  methods: {
    ...mapActions({
      fetchStatistics(dispatch) {
        return dispatch(`${this.storeNamespace}/fetchStatistics`);
      },
    }),
  },
};
</script>

<template>
  <div class="my-3">
    <h4 data-testid="chartTitle" class="h4">{{ title }}</h4>

    <loading-skeleton v-if="isLoading" class="mt-3" />

    <template v-else-if="hasHistory">
      <h5 data-testid="chartSubtitle" class="h5">{{ subtitle }}</h5>
      <statistics-summary class="mt-3" :data="summary" />
      <statistics-history class="mt-3" :data="chart" :y-legend="yLegend" />
    </template>

    <gl-empty-state
      v-else
      data-testid="chartEmptyState"
      :title="chartEmptyStateTitle"
      :description="chartEmptyStateText"
      :svg-path="chartEmptyStateSvgPath"
      :primary-button-link="documentationFullPath"
      :primary-button-text="__('Learn more')"
      compact
    />
  </div>
</template>
