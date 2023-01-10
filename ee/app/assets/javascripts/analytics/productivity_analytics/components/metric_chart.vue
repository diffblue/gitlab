<script>
import { GlDropdown, GlDropdownItem, GlLoadingIcon, GlAlert, GlIcon } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { s__ } from '~/locale';

export default {
  name: 'MetricChart',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlLoadingIcon,
    GlAlert,
    GlIcon,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    errorCode: {
      type: Number,
      required: false,
      default: null,
    },
    metricTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
    selectedMetric: {
      type: String,
      required: false,
      default: '',
    },
    chartData: {
      type: [Object, Array],
      required: false,
      default: () => [],
    },
  },
  computed: {
    hasMetricTypes() {
      return this.metricTypes.length;
    },
    metricDropdownLabel() {
      const foundMetric = this.metricTypes.find((m) => m.key === this.selectedMetric);
      return foundMetric ? foundMetric.label : s__('MetricChart|Please select a metric');
    },
    isServerError() {
      return this.errorCode === HTTP_STATUS_INTERNAL_SERVER_ERROR;
    },
    hasChartData() {
      return !isEmpty(this.chartData);
    },
    infoMessage() {
      if (this.isServerError) {
        return s__(
          'MetricChart|There is too much data to calculate. Please change your selection.',
        );
      } else if (!this.hasChartData) {
        return s__('MetricChart|There is no data available. Please change your selection.');
      }

      return null;
    },
  },
  methods: {
    isSelectedMetric(key) {
      return this.selectedMetric === key;
    },
  },
};
</script>
<template>
  <div>
    <h5 v-if="title">{{ title }}</h5>
    <gl-loading-icon v-if="isLoading" size="lg" class="my-4 py-4" />
    <template v-else>
      <gl-alert v-if="infoMessage" :dismissible="false">{{ infoMessage }}</gl-alert>
      <template v-else>
        <gl-dropdown
          v-if="hasMetricTypes"
          class="mb-4 metric-dropdown"
          toggle-class="dropdown-menu-toggle w-100"
          menu-class="w-100 mw-100"
          :text="metricDropdownLabel"
        >
          <gl-dropdown-item
            v-for="metric in metricTypes"
            :key="metric.key"
            active-class="is-active"
            class="w-100"
            @click="$emit('metricTypeChange', metric.key)"
          >
            <span class="d-flex">
              <gl-icon
                :title="s__('MetricChart|Selected')"
                class="flex-shrink-0 gl-mr-2"
                :class="{
                  invisible: !isSelectedMetric(metric.key),
                }"
                name="mobile-issue-close"
                :aria-label="s__('MetricChart|Selected')"
              />
              {{ metric.label }}
            </span>
          </gl-dropdown-item>
        </gl-dropdown>
        <p v-if="description" class="text-muted">{{ description }}</p>
        <div ref="chart">
          <slot v-if="hasChartData"></slot>
        </div>
      </template>
    </template>
  </div>
</template>
