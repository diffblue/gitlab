<script>
import TracingDetailsSpansChart from './tracing_details_spans_chart.vue';
import { mapTraceToTreeRoot, durationNanoToMs, assignColorToServices } from './trace_utils';

export default {
  components: {
    TracingDetailsSpansChart,
  },
  props: {
    trace: {
      required: true,
      type: Object,
    },
    selectedSpanId: {
      required: false,
      type: String,
      default: null,
    },
  },
  computed: {
    spans() {
      const root = mapTraceToTreeRoot(this.trace);
      return [root];
    },
    traceDurationMs() {
      return durationNanoToMs(this.trace.duration_nano);
    },
    serviceToColor() {
      return assignColorToServices(this.trace);
    },
  },
  methods: {
    onSelect({ spanId }) {
      this.$emit('span-selected', { spanId });
    },
  },
};
</script>

<template>
  <tracing-details-spans-chart
    :spans="spans"
    :trace-duration-ms="traceDurationMs"
    :service-to-color="serviceToColor"
    :selected-span-id="selectedSpanId"
    @span-selected="onSelect"
  />
</template>
