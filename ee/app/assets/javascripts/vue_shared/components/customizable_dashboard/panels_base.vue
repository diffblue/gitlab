<script>
import * as Sentry from '@sentry/browser';
import { GlIcon, GlLink, GlLoadingIcon, GlPopover, GlSprintf, GlButton } from '@gitlab/ui';
import dataSources from 'ee/analytics/analytics_dashboards/data_sources';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { isEmptyPanelData } from 'ee/vue_shared/components/customizable_dashboard/utils';
import {
  I18N_PANEL_EMPTY_STATE_MESSAGE,
  I18N_PANEL_ERROR_POPOVER_MESSAGE,
  I18N_PANEL_ERROR_POPOVER_TITLE,
  I18N_PANEL_ERROR_STATE_MESSAGE,
  I18N_PANEL_ERROR_POPOVER_RETRY_BUTTON_TITLE,
  PANEL_TROUBLESHOOTING_URL,
  PANEL_POPOVER_DELAY,
} from './constants';

export default {
  name: 'AnalyticsDashboardPanel',
  components: {
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlPopover,
    GlSprintf,
    GlButton,
    TooltipOnTruncate,
    LineChart: () =>
      import('ee/analytics/analytics_dashboards/components/visualizations/line_chart.vue'),
    ColumnChart: () =>
      import('ee/analytics/analytics_dashboards/components/visualizations/column_chart.vue'),
    DataTable: () =>
      import('ee/analytics/analytics_dashboards/components/visualizations/data_table.vue'),
    SingleStat: () =>
      import('ee/analytics/analytics_dashboards/components/visualizations/single_stat.vue'),
  },
  inject: ['namespaceId'],
  props: {
    visualization: {
      type: Object,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    queryOverrides: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    filters: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      error: null,
      data: null,
      loading: true,
    };
  },
  computed: {
    showEmptyState() {
      return !this.error && isEmptyPanelData(this.visualization.type, this.data);
    },
    showErrorState() {
      return Boolean(this.error);
    },
  },
  watch: {
    visualization: {
      handler: 'fetchData',
      immediate: true,
    },
    queryOverrides: 'fetchData',
    filters: 'fetchData',
  },
  methods: {
    async fetchData() {
      const { queryOverrides, filters } = this;
      const { type: dataType, query } = this.visualization.data;
      this.loading = true;
      this.error = null;

      try {
        const { fetch } = await dataSources[dataType]();
        this.data = await fetch({
          projectId: this.namespaceId,
          query,
          queryOverrides,
          visualizationType: this.visualization.type,
          visualizationOptions: this.visualization.options,
          filters,
        });
      } catch (error) {
        this.error = error;
        Sentry.captureException(error);
      } finally {
        this.loading = false;
      }
    },
  },
  I18N_PANEL_EMPTY_STATE_MESSAGE,
  I18N_PANEL_ERROR_STATE_MESSAGE,
  I18N_PANEL_ERROR_POPOVER_TITLE,
  I18N_PANEL_ERROR_POPOVER_MESSAGE,
  I18N_PANEL_ERROR_POPOVER_RETRY_BUTTON_TITLE,
  PANEL_TROUBLESHOOTING_URL,
  PANEL_POPOVER_DELAY,
};
</script>

<template>
  <div
    ref="panelWrapper"
    class="grid-stack-item-content gl-shadow-sm gl-rounded-base gl-p-4 gl-display-flex gl-flex-direction-column gl-bg-white"
    :class="{ 'gl-border-t-2 gl-border-t-solid gl-border-red-500': showErrorState }"
  >
    <tooltip-on-truncate
      v-if="title"
      :title="title"
      placement="top"
      boundary="viewport"
      class="gl-pb-3 gl-text-truncate"
    >
      <gl-icon v-if="showErrorState" name="warning" class="gl-text-red-500" />
      <strong>{{ title }}</strong>
    </tooltip-on-truncate>
    <div class="gl-overflow-y-auto gl-h-full" :class="{ 'gl--flex-center': loading }">
      <gl-loading-icon v-if="loading" size="lg" />

      <div v-else-if="showEmptyState" class="gl-text-secondary">
        {{ $options.I18N_PANEL_EMPTY_STATE_MESSAGE }}
      </div>

      <div v-else-if="showErrorState" class="gl-text-secondary">
        {{ $options.I18N_PANEL_ERROR_STATE_MESSAGE }}
      </div>

      <component
        :is="visualization.type"
        v-else-if="!error"
        :data="data"
        :options="visualization.options"
      />
    </div>

    <gl-popover
      v-if="showErrorState"
      triggers="hover focus"
      :title="$options.I18N_PANEL_ERROR_POPOVER_TITLE"
      :show-close-button="false"
      placement="top"
      :target="$refs.panelWrapper"
      :delay="$options.PANEL_POPOVER_DELAY"
    >
      <gl-sprintf :message="$options.I18N_PANEL_ERROR_POPOVER_MESSAGE">
        <template #link="{ content }">
          <gl-link :href="$options.PANEL_TROUBLESHOOTING_URL" class="gl-font-sm">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
      <gl-button class="gl-display-block gl-mt-3" @click="fetchData">{{
        $options.I18N_PANEL_ERROR_POPOVER_RETRY_BUTTON_TITLE
      }}</gl-button>
    </gl-popover>
  </div>
</template>
