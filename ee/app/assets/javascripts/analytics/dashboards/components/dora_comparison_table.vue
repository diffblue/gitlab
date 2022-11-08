<script>
import { GlTableLite } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
import { DASHBOARD_TABLE_FIELDS } from '../constants';

export default {
  name: 'DoraComparisonTable',
  components: {
    GlTableLite,
  },
  props: {
    data: {
      type: Array,
      required: true,
    },
  },
  fields: DASHBOARD_TABLE_FIELDS,
  methods: {
    formatDate(date) {
      return formatDate(date, 'mmm d');
    },
  },
};
</script>
<template>
  <gl-table-lite :fields="$options.fields" :items="data">
    <template #head()="{ field: { label, start, end } }">
      <template v-if="!start || !end">
        {{ label }}
      </template>
      <template v-else>
        <div class="gl-mb-2">{{ label }}</div>
        <div class="gl-font-weight-normal">{{ formatDate(start) }} - {{ formatDate(end) }}</div>
      </template>
    </template>
  </gl-table-lite>
</template>
