<script>
import { GlAlert, GlSkeletonLoader, GlTableLite } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { METRICS_REQUESTS } from '~/cycle_analytics/constants';
import { fetchMetricsData } from 'ee/api/dora_api';
import {
  COMPARISON_INTERVAL_IN_DAYS,
  DASHBOARD_TABLE_FIELDS,
  DASHBOARD_LOADING_FAILURE_MESSAGE,
  DASHBOARD_NO_DATA_MESSAGE,
} from './constants';
import { toUtcYMD, extractDoraMetrics, generateComparison } from './utils';

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
    GlTableLite,
  },
  props: {
    groupFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      startDate: toUtcYMD(DEFAULT_END_DATE),
      endDate: toUtcYMD(DEFAULT_TODAY),
      previousStartDate: toUtcYMD(COMPARATIVE_START_DATE),
      data: [],
      loading: false,
    };
  },
  computed: {
    hasData() {
      return Boolean(this.data.length);
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
          this.data = generateComparison(response);
        })
        .catch(() => createAlert({ message: DASHBOARD_LOADING_FAILURE_MESSAGE }))
        .finally(() => {
          this.loading = false;
        });
    },
  },
  fields: DASHBOARD_TABLE_FIELDS,
  noData: DASHBOARD_NO_DATA_MESSAGE,
};
</script>
<template>
  <div>
    <!-- <p>Current: {{ startDate }} -> {{ endDate }}</p>
    <p>previous: {{ previousStartDate }} -> {{ startDate }}</p> -->
    <gl-skeleton-loader v-if="loading" />
    <!-- TODO: maybe add a tool tip over the table headers for the date range -->
    <gl-table-lite v-else-if="hasData" :fields="$options.fields" :items="data" />
    <gl-alert v-else variant="info" :dismissible="false">{{ $options.noData }}</gl-alert>
  </div>
</template>
