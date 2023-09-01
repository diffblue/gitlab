<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl, isSafeURL } from '~/lib/utils/url_utility';
import TracingDetailsChart from './tracing_details_chart.vue';
import TracingDetailsHeader from './tracing_details_header.vue';
import TracingDetailsDrawer from './tracing_details_drawer.vue';

export default {
  i18n: {
    error: s__('Tracing|Failed to load trace details.'),
  },
  components: {
    GlLoadingIcon,
    TracingDetailsChart,
    TracingDetailsHeader,
    TracingDetailsDrawer,
  },
  props: {
    observabilityClient: {
      required: true,
      type: Object,
    },
    traceId: {
      required: true,
      type: String,
    },
    tracingIndexUrl: {
      required: true,
      type: String,
      validator: (val) => isSafeURL(val),
    },
  },
  data() {
    return {
      trace: null,
      loading: false,
      isDrawerOpen: false,
      selectedSpan: null,
    };
  },
  created() {
    this.validateAndFetch();
  },
  methods: {
    async validateAndFetch() {
      if (!this.traceId) {
        createAlert({
          message: this.$options.i18n.error,
        });
      }
      this.loading = true;
      try {
        const enabled = await this.observabilityClient.isTracingEnabled();
        if (enabled) {
          await this.fetchTrace();
        } else {
          this.goToTracingIndex();
        }
      } catch (e) {
        createAlert({
          message: this.$options.i18n.error,
        });
      } finally {
        this.loading = false;
      }
    },
    async fetchTrace() {
      this.loading = true;
      try {
        this.trace = await this.observabilityClient.fetchTrace(this.traceId);
      } catch (e) {
        createAlert({
          message: this.$options.i18n.error,
        });
      } finally {
        this.loading = false;
      }
    },
    goToTracingIndex() {
      visitUrl(this.tracingIndexUrl);
    },
    onToggleDrawer({ spanId }) {
      if (this.isDrawerOpen) {
        this.closeDrawer();
      } else {
        const span = this.trace.spans.find((s) => s.span_id === spanId);
        this.selectedSpan = span;
        this.isDrawerOpen = true;
      }
    },
    closeDrawer() {
      this.selectedSpan = null;
      this.isDrawerOpen = false;
    },
  },
};
</script>

<template>
  <div v-if="loading" class="gl-py-5">
    <gl-loading-icon size="lg" />
  </div>

  <div v-else-if="trace" data-testid="trace-details" class="gl-mx-7">
    <tracing-details-header :trace="trace" />
    <tracing-details-chart
      :trace="trace"
      :selected-span-id="selectedSpan && selectedSpan.span_id"
      @span-selected="onToggleDrawer"
    />

    <tracing-details-drawer :span="selectedSpan" :open="isDrawerOpen" @close="closeDrawer" />
  </div>
</template>
