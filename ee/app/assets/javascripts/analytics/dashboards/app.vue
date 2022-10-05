<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { flatten } from 'lodash';
import { createAlert } from '~/flash';
import { sprintf, s__ } from '~/locale';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { METRICS_POPOVER_CONTENT } from '~/analytics/shared/constants';
import { prepareTimeMetricsData } from '~/analytics/shared/utils';
import { METRICS_REQUESTS } from '~/cycle_analytics/constants';

import { COMPARISON_INTERVAL_IN_DAYS } from './constants';
import { toUtcYMD, extractDoraMetrics, generateComparison } from './utils';
import ComparativeTable from './comparative_table.vue';

export const DEFAULT_TODAY = new Date();
export const DEFAULT_END_DATE = getDateInPast(DEFAULT_TODAY, COMPARISON_INTERVAL_IN_DAYS - 1);
export const COMPARATIVE_START_DATE = getDateInPast(
  DEFAULT_END_DATE,
  COMPARISON_INTERVAL_IN_DAYS - 1,
);

const requestData = ({ request, endpoint, path, params, name }) => {
  return request({ endpoint, params, requestPath: path })
    .then(({ data }) => data)
    .catch(() => {
      const message = sprintf(
        s__(
          'ValueStreamAnalytics|There was an error while fetching value stream analytics %{requestTypeName} data.',
        ),
        { requestTypeName: name },
      );
      createAlert({ message });
    });
};

// Copied from value_stream_metrics
// TODO: refactor to shared api file
const fetchMetricsData = (reqs = [], path, params) => {
  const promises = reqs.map((r) => requestData({ ...r, path, params }));
  return Promise.all(promises).then((responses) =>
    prepareTimeMetricsData(flatten(responses), METRICS_POPOVER_CONTENT),
  );
};

const fetchDoraTimePeriods = async ({ startDate, endDate, previousStartDate, groupFullPath }) => {
  const path = `groups/${groupFullPath}`;

  const promises = [
    fetchMetricsData(METRICS_REQUESTS, path, {
      created_after: startDate,
      created_before: endDate,
    }),
    fetchMetricsData(METRICS_REQUESTS, path, {
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
    GlSkeletonLoader,
    ComparativeTable,
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
      error: null,
    };
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    fetchData() {
      this.loading = true;

      fetchDoraTimePeriods({
        startDate: this.startDate,
        endDate: this.endDate,
        previousStartDate: this.previousStartDate,
        groupFullPath: this.groupFullPath,
      })
        .then((response) => {
          this.data = generateComparison(response);
        })
        .catch((err) => {
          createAlert('Failed to load', err);
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>
<template>
  <div>
    <p>Current: {{ startDate }} -> {{ endDate }}</p>
    <p>previous: {{ previousStartDate }} -> {{ startDate }}</p>
    <gl-skeleton-loader v-if="loading" />
    <!-- TODO: maybe add a tool tip over the table headers for the date range -->
    <comparative-table v-else :data="data" />
  </div>
</template>
