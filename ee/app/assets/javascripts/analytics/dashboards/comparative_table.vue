<script>
import { GlTableLite } from '@gitlab/ui';
import {
  DASHBOARD_COLUMN_TITLE_CHANGE,
  DASHBOARD_COLUMN_TITLE_CURRENT,
  DASHBOARD_COLUMN_TITLE_METRIC,
  DASHBOARD_COLUMN_TITLE_PREVIOUS,
} from './constants';

export default {
  name: 'ComparativeTable',
  components: { GlTableLite },
  props: {
    data: {
      type: Array,
      required: true,
    },
  },
  fields: [
    {
      key: 'metric',
      label: DASHBOARD_COLUMN_TITLE_METRIC,
    },
    {
      key: 'current',
      label: DASHBOARD_COLUMN_TITLE_CURRENT,
    },
    {
      key: 'previous',
      label: DASHBOARD_COLUMN_TITLE_PREVIOUS,
    },
    {
      key: 'change',
      label: DASHBOARD_COLUMN_TITLE_CHANGE,
    },
  ],
};
</script>
<template>
  <gl-table-lite :fields="$options.fields" :items="data" />
</template>
