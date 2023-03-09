<script>
import { GlTableLite } from '@gitlab/ui';

export default {
  name: 'DataTable',
  components: {
    GlTableLite,
  },
  props: {
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
    // Part of the visualizations API, but left unused for tables.
    // It could be used down the line to allow users to customize tables.
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    fields() {
      if (this.data.length < 1) {
        return null;
      }

      return Object.keys(this.data[0]).map((key) => ({
        key,
        tdClass: 'gl-text-truncate gl-max-w-0',
      }));
    },
  },
};
</script>

<template>
  <div>
    <gl-table-lite :fields="fields" :items="data" hover responsive class="gl-mt-4" />
  </div>
</template>
