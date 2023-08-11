<script>
import { uniqueId } from 'lodash';
import { __, n__, s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';

export default {
  name: 'WidgetMetrics',
  components: {
    MrWidget,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    label: s__('Reports|metrics report'),
    loading: s__('Reports|Metrics reports are loading'),
    error: s__('Reports|Metrics reports failed to load results'),
  },
  data() {
    return {
      collapsedData: {},
      content: [],
    };
  },
  computed: {
    numberOfChanges() {
      const changedMetrics =
        this.collapsedData?.existing_metrics?.filter((metric) => metric?.previous_value) || [];
      const newMetrics = this.collapsedData?.new_metrics || [];
      const removedMetrics = this.collapsedData?.removed_metrics || [];

      return changedMetrics.length + newMetrics.length + removedMetrics.length;
    },
    hasChanges() {
      return this.numberOfChanges > 0;
    },
    statusIcon() {
      return this.hasChanges ? EXTENSION_ICONS.warning : EXTENSION_ICONS.success;
    },
    shouldCollapse() {
      return this.hasChanges;
    },
    apiMetricsPath() {
      return this.mr.metricsReportsPath;
    },
    summary() {
      const { hasChanges, numberOfChanges } = this;
      const changesSummary = sprintf(
        s__('Reports|Metrics reports: %{strong_start}%{numberOfChanges}%{strong_end} %{changes}'),
        {
          numberOfChanges,
          changes: n__('change', 'changes', numberOfChanges),
        },
      );
      const noChangesSummary = s__('Reports|Metrics report scanning detected no new changes');
      return hasChanges ? { title: changesSummary } : { title: noChangesSummary };
    },
  },
  methods: {
    fetchCollapsedData() {
      return axios.get(this.apiMetricsPath).then((response) => {
        this.collapsedData = response.data;
        this.content = this.getContent(response.data);

        return response;
      });
    },
    formatMetricDelta(metric) {
      // calculate metric delta for sorting if numeric
      const delta = Math.abs(parseFloat(metric.value) - parseFloat(metric.previous_value));

      // give non-numeric metrics high delta so they appear first
      return Number.isNaN(delta) ? Infinity : delta;
    },
    getContent(collapsedData) {
      const {
        new_metrics: newMetrics = [],
        existing_metrics: existingMetrics = [],
        removed_metrics: removedMetrics = [],
      } = collapsedData;

      return [
        ...newMetrics.map((metric, index) => {
          return {
            header: index === 0 ? __('New') : '',
            id: uniqueId('new-metric-'),
            text: `${metric.name}: ${metric.value}`,
            icon: { name: EXTENSION_ICONS.neutral },
          };
        }),
        ...removedMetrics.map((metric, index) => {
          return {
            header: index === 0 ? __('Removed') : '',
            id: uniqueId('resolved-metric-'),
            text: `${metric.name}: ${metric.value}`,
            icon: { name: EXTENSION_ICONS.neutral },
          };
        }),
        ...existingMetrics
          .filter((metric) => metric?.previous_value)
          .map((metric) => {
            return {
              id: uniqueId('changed-metric-'),
              text: `${metric.name}: ${metric.value} (${metric.previous_value})`,
              icon: { name: EXTENSION_ICONS.neutral },
              delta: this.formatMetricDelta(metric),
            };
          })
          .sort((a, b) => b.delta - a.delta)
          .map((metric, index) => {
            return {
              header: index === 0 ? __('Changed') : '',
              ...metric,
            };
          }),
        ...existingMetrics
          .filter((metric) => !metric?.previous_value)
          .map((metric, index) => {
            return {
              header: index === 0 ? __('No changes') : '',
              id: uniqueId('unchanged-metric-'),
              text: `${metric.name}: ${metric.value}`,
              icon: { name: EXTENSION_ICONS.neutral },
            };
          }),
      ];
    },
  },
};
</script>
<template>
  <mr-widget
    :error-text="$options.i18n.error"
    :status-icon-name="statusIcon"
    :loading-text="$options.i18n.loading"
    :help-popover="$options.helpPopover"
    :widget-name="$options.name"
    :summary="summary"
    :content="content"
    :is-collapsible="shouldCollapse"
    :fetch-collapsed-data="fetchCollapsedData"
  />
</template>
