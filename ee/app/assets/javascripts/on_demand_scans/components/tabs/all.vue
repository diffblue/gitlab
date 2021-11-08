<script>
import { __, s__ } from '~/locale';
import onDemandScansQuery from '../../graphql/on_demand_scans.query.graphql';
import BaseTab from './base_tab.vue';

export default {
  query: onDemandScansQuery,
  components: {
    BaseTab,
  },
  tableFields: [
    {
      label: __('Status'),
      key: 'detailedStatus',
      columnClass: 'gl-w-15',
    },
    {
      label: __('Name'),
      key: 'dastProfile.name',
    },
    {
      label: s__('OnDemandScans|Scan type'),
      key: 'scanType',
      columnClass: 'gl-w-13',
    },
    {
      label: s__('OnDemandScans|Target'),
      key: 'dastProfile.dastSiteProfile.targetUrl',
    },
    {
      label: __('Start date'),
      key: 'createdAt',
      columnClass: 'gl-w-15',
    },
    {
      label: __('Pipeline'),
      key: 'id',
      columnClass: 'gl-w-13',
    },
  ],
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
