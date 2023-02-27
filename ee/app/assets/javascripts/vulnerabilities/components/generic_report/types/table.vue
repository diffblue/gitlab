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
    class="gl-m-0!"
    thead-class="gl-border-t-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
    tbody-tr-class="gl-word-break-all"
  >
    <template #head()="data">
      <report-item :item="data.field" />
    </template>
    <template #cell()="data">
      <report-item :item="data.value" />
    </template>
  </gl-table-lite>
</template>
