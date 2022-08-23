<script>
import DateRange from '~/analytics/shared/components/daterange.vue';
import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { DEFAULT_NUMBER_OF_DAYS } from '../constants';
import FilterBar from './filter_bar.vue';
import ThroughputChart from './throughput_chart.vue';
import ThroughputTable from './throughput_table.vue';

export default {
  name: 'MergeRequestAnalyticsApp',
  components: {
    DateRange,
    FilterBar,
    ThroughputChart,
    ThroughputTable,
    UrlSync,
  },
  props: {
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
  },
  computed: {
    query() {
      return {
        start_date: dateFormat(this.startDate, dateFormats.isoDate),
        end_date: dateFormat(this.endDate, dateFormats.isoDate),
      };
    },
  },
  methods: {
    setDateRange({ startDate, endDate }) {
      // eslint-disable-next-line vue/no-mutating-props
      this.startDate = startDate;
      // eslint-disable-next-line vue/no-mutating-props
      this.endDate = endDate;
    },
  },
  dateRangeLimit: DEFAULT_NUMBER_OF_DAYS,
};
</script>
<template>
  <div class="merge-request-analytics-wrapper">
    <h3 data-testid="pageTitle" class="gl-mb-5">{{ __('Merge Request Analytics') }}</h3>
    <div
      class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-justify-content-space-between gl-bg-gray-10 gl-border-t-solid gl-border-t-1 gl-border-t-gray-100 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-py-3"
    >
      <filter-bar class="gl-flex-grow-1 gl-lg-ml-3 gl-mb-2 gl-lg-mb-0" />
      <date-range
        :start-date="startDate"
        :end-date="endDate"
        :max-date-range="$options.dateRangeLimit"
        class="gl-lg-mx-3"
        @change="setDateRange"
      />
    </div>
    <throughput-chart :start-date="startDate" :end-date="endDate" />
    <throughput-table :start-date="startDate" :end-date="endDate" class="gl-mt-6" />
    <url-sync :query="query" />
  </div>
</template>
