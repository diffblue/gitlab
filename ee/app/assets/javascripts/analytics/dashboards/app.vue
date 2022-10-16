<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { createAlert } from '~/flash';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { METRICS_REQUESTS } from '~/cycle_analytics/constants';
import { fetchMetricsData } from '~/analytics/shared/utils';
import DoraComparisonTable from './dora_comparison_table.vue';
import {
  COMPARISON_INTERVAL_IN_DAYS,
  DASHBOARD_TITLE,
  DASHBOARD_DESCRIPTION,
  DASHBOARD_LOADING_FAILURE,
  DASHBOARD_NO_DATA,
} from './constants';
import { toUtcYmd, extractDoraMetrics, generateDoraTimePeriodComparisonTable } from './utils';

export const DEFAULT_TODAY = new Date();
export const DEFAULT_END_DATE = getDateInPast(DEFAULT_TODAY, COMPARISON_INTERVAL_IN_DAYS - 1);
export const COMPARATIVE_START_DATE = getDateInPast(
  DEFAULT_END_DATE,
  COMPARISON_INTERVAL_IN_DAYS - 1,
);

const fetchComparativeDoraTimePeriods = async ({
  startDate,
  endDate,
  previousStartDate,
  requestPath,
}) => {
  const promises = [
    fetchMetricsData(METRICS_REQUESTS, requestPath, {
      created_after: startDate,
      created_before: endDate,
    }),
    fetchMetricsData(METRICS_REQUESTS, requestPath, {
      created_after: previousStartDate,
      created_before: startDate,
    }),
  ];

  const [current, previous] = await Promise.all(promises);
  return { current: extractDoraMetrics(current), previous: extractDoraMetrics(previous) };
};

export default {
  name: 'DashboardsApp',
  components: {
    GlAlert,
    GlSkeletonLoader,
    DoraComparisonTable,
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
    groupName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      startDate: toUtcYmd(DEFAULT_END_DATE),
      endDate: toUtcYmd(DEFAULT_TODAY),
      previousStartDate: toUtcYmd(COMPARATIVE_START_DATE),
      data: [],
      loading: false,
    };
  },
  computed: {
    hasData() {
      return Boolean(this.data.length);
    },
    description() {
      const { groupName } = this;
      return sprintf(this.$options.i18n.description, { groupName });
    },
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    fetchData() {
      this.loading = true;

      fetchComparativeDoraTimePeriods({
        startDate: this.startDate,
        endDate: this.endDate,
        previousStartDate: this.previousStartDate,
        requestPath: `groups/${this.groupFullPath}`,
      })
        .then((response) => {
          this.data = generateDoraTimePeriodComparisonTable(response);
        })
        .catch(() => createAlert({ message: DASHBOARD_LOADING_FAILURE }))
        .finally(() => {
          this.loading = false;
        });
    },
  },
  i18n: {
    title: DASHBOARD_TITLE,
    description: DASHBOARD_DESCRIPTION,
    noData: DASHBOARD_NO_DATA,
  },
};
</script>
<template>
  <div>
    <h1 class="page-title">{{ $options.i18n.title }}</h1>
    <h4>{{ description }}</h4>
    <gl-skeleton-loader v-if="loading" />
    <dora-comparison-table v-else-if="hasData" :data="data" />
    <gl-alert v-else variant="info" :dismissible="false">{{ $options.i18n.noData }}</gl-alert>
  </div>
</template>
