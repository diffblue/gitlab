<script>
import { GlTable } from '@gitlab/ui';
import { DASHBOARD_TABLE_FIELDS } from './constants';

export default {
  name: 'DoraComparisonTable',
  components: {
    GlTable,
  },
  props: {
    data: {
      type: Array,
      required: true,
    },
  },
  fields: DASHBOARD_TABLE_FIELDS,
};
</script>
<template>
  <gl-table :fields="$options.fields" :items="data" />
</template>
