<script>
import { GlDrawer } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import { formatTraceDuration } from './trace_utils';

export default {
  components: {
    GlDrawer,
  },
  i18n: {
    drawerTitle: s__('Tracing|Span Details'),
  },
  props: {
    span: {
      required: false,
      type: Object,
      default: null,
    },
    open: {
      required: true,
      type: Boolean,
    },
  },
  computed: {
    spanTitle() {
      return `${this.span.service_name} : ${this.span.operation}`;
    },
    content() {
      if (this.span) {
        return [
          { title: s__('Tracing|Span ID'), value: this.span.span_id },
          { title: s__('Tracing|Trace ID'), value: this.span.trace_id },
          { title: s__('Tracing|Date'), value: formatDate(this.span.timestamp) },
          { title: s__('Tracing|Service'), value: this.span.service_name },
          { title: s__('Tracing|Operation'), value: this.span.operation },
          {
            title: s__('Tracing|Duration'),
            value: formatTraceDuration(this.span.duration_nano),
          },
          {
            title: s__('Tracing|Status Code'),
            value: this.span.statusCode,
          },
        ];
      }
      return [];
    },
  },
  DRAWER_Z_INDEX,
};
</script>

<template>
  <gl-drawer :open="open" :z-index="$options.DRAWER_Z_INDEX" @close="$emit('close')">
    <template #title>
      <div data-testid="span-title">
        <h2 class="gl-font-size-h2 gl-mt-0 gl-mb-4">{{ $options.i18n.drawerTitle }}</h2>
        <span class="gl-font-lg">{{ spanTitle }}</span>
      </div>
    </template>
    <template #default>
      <div v-for="section in content" :key="section.title">
        <label data-testid="section-title" class="gl-font-weight-bold">{{ section.title }}</label>
        <div data-testid="section-value">{{ section.value }}</div>
      </div>
    </template>
  </gl-drawer>
</template>
