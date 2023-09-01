<script>
import { GlButton, GlTruncate } from '@gitlab/ui';
import { clamp } from 'lodash';
import { s__ } from '~/locale';
import { formatDurationMs } from './trace_utils';

export default {
  name: 'TracingDetailsSpansChart',
  components: {
    GlButton,
    GlTruncate,
  },
  i18n: {
    toggleChildrenSpans: s__('Tracing|Toggle children spans'),
  },
  props: {
    spans: {
      required: true,
      type: Array,
    },
    traceDurationMs: {
      required: true,
      type: Number,
    },
    depth: {
      required: false,
      type: Number,
      default: 0,
    },
    serviceToColor: {
      required: true,
      type: Object,
    },
    selectedSpanId: {
      required: false,
      type: String,
      default: null,
    },
  },
  data() {
    return {
      expanded: this.expandedState(this.spans),
    };
  },
  computed: {
    spanDetailsStyle() {
      return {
        paddingLeft: `${this.depth * 16}px`,
      };
    },
  },
  watch: {
    spans(_, newSpans) {
      this.expanded = this.expandedState(newSpans);
    },
  },
  methods: {
    expandedState(spans) {
      return spans.map((x) => x.children.length > 0);
    },
    hasChildrenSpans(index) {
      return this.spans[index].children.length > 0;
    },
    toggleExpand(index) {
      if (!this.hasChildrenSpans(index)) return;

      this.$set(this.expanded, index, !this.isExpanded(index));
    },
    isExpanded(index) {
      return this.expanded[index];
    },
    durationWrapperStyle(span) {
      const l = Math.floor((100 * span.startTimeMs) / this.traceDurationMs);
      return {
        marginLeft: `${l}%`,
      };
    },
    durationLineStyle(span) {
      const w = clamp((100 * span.durationMs) / this.traceDurationMs, 0.5, 100);
      return {
        width: `${w}%`,
        height: '32px',
        borderRadius: '4px',
      };
    },
    durationValue(span) {
      return formatDurationMs(span.durationMs);
    },
    onSelect({ spanId }) {
      this.$emit('span-selected', { spanId });
    },
    isSpanSelected(span) {
      return span.spanId === this.selectedSpanId;
    },
  },
};
</script>

<template>
  <div class="span-tree">
    <div
      v-for="(span, index) in spans"
      :key="span.spanId"
      :data-testid="`span-wrapper-${depth}-${index}`"
    >
      <div
        data-testid="span-inner-container"
        class="gl-display-flex gl-border-b gl-cursor-pointer"
        :class="{
          'gl-bg-blue-100': isSpanSelected(span),
          'gl-hover-bg-t-gray-a-08': !isSpanSelected(span),
        }"
        @click="onSelect({ spanId: span.spanId })"
      >
        <div
          data-testid="span-details"
          class="gl-w-30p gl-min-w-20 gl-display-flex gl-flex-direction-row gl-p-3 gl-border-r"
          :style="spanDetailsStyle"
        >
          <div>
            <gl-button
              :aria-label="$options.i18n.toggleChildrenSpans"
              class="gl-mr-1"
              :class="{ invisible: !hasChildrenSpans(index) }"
              :icon="`chevron-${isExpanded(index) ? 'down' : 'up'}`"
              category="tertiary"
              size="small"
              @click.stop="toggleExpand(index)"
            />
          </div>

          <div class="gl-display-flex gl-flex-direction-column gl-text-truncate">
            <gl-truncate
              class="gl-font-weight-bold gl-text-primary"
              :text="span.operation"
              with-tooltip
            />
            <gl-truncate class="gl-text-secondary" :text="span.service" with-tooltip />
          </div>
        </div>

        <div
          class="gl-display-flex gl-flex-grow-1 gl-flex-direction-column gl-justify-content-center gl-px-4 gl-py-3"
        >
          <div :style="durationWrapperStyle(span)" data-testid="span-duration">
            <div
              data-testid="span-duration-bar"
              :style="durationLineStyle(span)"
              :class="`gl-bg-data-viz-${serviceToColor[span.service]}`"
            ></div>
            <span class="gl-text-secondary">{{ durationValue(span) }}</span>
          </div>
        </div>
      </div>

      <tracing-details-spans-chart
        v-if="isExpanded(index)"
        :spans="span.children"
        :depth="depth + 1"
        :trace-duration-ms="traceDurationMs"
        :service-to-color="serviceToColor"
        :selected-span-id="selectedSpanId"
        @span-selected="onSelect"
      />
    </div>
  </div>
</template>
