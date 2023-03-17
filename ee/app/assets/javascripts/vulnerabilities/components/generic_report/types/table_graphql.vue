<script>
import { GlTableLite } from '@gitlab/ui';

export default {
  components: {
    GlTableLite,
    ReportItem: () => import('../report_item_graphql.vue'),
  },
  inheritAttrs: false,
  props: {
    headers: {
      type: Array,
      required: true,
    },
    rows: {
      type: Array,
      required: true,
    },
  },
  computed: {
    fields() {
      // adds an index-based key to each header, so it can be mapped to an item (table data)
      const addColumnIndex = (headerValues, i) => ({ ...headerValues, key: `column_${i}` });

      return this.headers.map(addColumnIndex);
    },
    items() {
      // creates an object for each item and wraps it with an index-based property, so it can be mapped to a field (table header)
      const wrapInColumn = ({ row }) =>
        Object.fromEntries(row.map((data, i) => [`column_${i}`, data]));

      return this.rows.map(wrapInColumn);
    },
  },
};
</script>
<template>
  <gl-table-lite :fields="fields" :items="items" bordered borderless>
    <template #head()="{ field }">
      <report-item :item="field" />
    </template>
    <template #cell()="{ value }">
      <report-item :item="value" />
    </template>
  </gl-table-lite>
</template>
