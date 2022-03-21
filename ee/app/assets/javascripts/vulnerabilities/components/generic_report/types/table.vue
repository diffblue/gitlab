<script>
import { GlTableLite } from '@gitlab/ui';

export default {
  components: {
    GlTableLite,
    ReportItem: () => import('../report_item.vue'),
  },
  inheritAttrs: false,
  props: {
    header: {
      type: Array,
      required: true,
    },
    rows: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <gl-table-lite
    :fields="header"
    :items="rows"
    bordered
    borderless
    thead-class="gl-border-t-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
  >
    <template #head()="data">
      <report-item :item="data.field" />
    </template>
    <template #cell()="data">
      <report-item :item="data.value" />
    </template>
  </gl-table-lite>
</template>
