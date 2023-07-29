<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { __ } from '~/locale';
import onDemandScansQuery from '../../graphql/on_demand_scans.query.graphql';
import { BASE_TABS_TABLE_FIELDS } from '../../constants';
import BaseTab from './base_tab.vue';

export default {
  query: onDemandScansQuery,
  components: {
    BaseTab,
  },
  tableFields: BASE_TABS_TABLE_FIELDS,
  i18n: {
    title: __('All'),
  },
};
</script>

<template>
  <base-tab
    v-bind="$attrs"
    :query="$options.query"
    :title="$options.i18n.title"
    :fields="$options.tableFields"
  />
</template>
