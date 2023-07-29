<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { __, s__ } from '~/locale';
import onDemandScansQuery from '../../graphql/on_demand_scans.query.graphql';
import { BASE_TABS_TABLE_FIELDS, PIPELINES_SCOPE_RUNNING, LEARN_MORE_TEXT } from '../../constants';
import BaseTab from './base_tab.vue';

export default {
  query: onDemandScansQuery,
  queryVariables: {
    scope: PIPELINES_SCOPE_RUNNING,
  },
  components: {
    BaseTab,
  },
  tableFields: BASE_TABS_TABLE_FIELDS,
  i18n: {
    title: __('Running'),
    emptyStateTitle: s__('OnDemandScans|There are no running scans.'),
    emptyStateText: LEARN_MORE_TEXT,
  },
};
</script>

<template>
  <base-tab
    :query="$options.query"
    :query-variables="$options.queryVariables"
    :title="$options.i18n.title"
    :fields="$options.tableFields"
    :empty-state-title="$options.i18n.emptyStateTitle"
    :empty-state-text="$options.i18n.emptyStateText"
    v-bind="$attrs"
  />
</template>
