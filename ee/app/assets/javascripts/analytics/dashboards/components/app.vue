<script>
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { createAlert } from '~/flash';
import {
  DASHBOARD_TITLE,
  DASHBOARD_DESCRIPTION,
  DASHBOARD_LOADING_FAILURE,
  DASHBOARD_NO_DATA,
  DASHBOARD_TIME_PERIODS,
} from '../constants';
import {
  fetchDoraMetrics,
  hasDoraMetricValues,
  generateDoraTimePeriodComparisonTable,
} from '../utils';
import DoraComparisonTable from './dora_comparison_table.vue';

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

      fetchDoraMetrics({
        timePeriods: DASHBOARD_TIME_PERIODS,
        requestPath: `groups/${this.groupFullPath}`,
      })
        .then((response) => {
          this.data = hasDoraMetricValues(response)
            ? generateDoraTimePeriodComparisonTable(response)
            : [];
        })
        .catch(() => {
          createAlert({ message: DASHBOARD_LOADING_FAILURE });
        })
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
