<script>
import { createAlert } from '~/flash';
import projectScannersQuery from 'ee/security_dashboard/graphql/queries/project_specific_scanners.query.graphql';
import groupScannersQuery from 'ee/security_dashboard/graphql/queries/group_specific_scanners.query.graphql';
import instanceScannersQuery from 'ee/security_dashboard/graphql/queries/instance_specific_scanners.query.graphql';
import { getFormattedScanners } from 'ee/security_dashboard/helpers';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { s__ } from '~/locale';
import SimpleFilter from './simple_filter.vue';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import { TOOL_FILTER_ERROR } from './constants';

const DASHBOARD_QUERIES = {
  [DASHBOARD_TYPES.PROJECT]: {
    query: projectScannersQuery,
    fullPath: 'fullPath',
    dataType: 'project',
  },
  [DASHBOARD_TYPES.GROUP]: {
    query: groupScannersQuery,
    fullPath: 'fullPath',
    dataType: 'group',
  },
  [DASHBOARD_TYPES.INSTANCE]: {
    query: instanceScannersQuery,
    fullPath: undefined,
    dataType: 'instanceSecurityDashboard',
  },
};

export default {
  name: 'ToolFilter',
  components: { FilterBody, FilterItem },
  extends: SimpleFilter,
  inject: ['dashboardType', 'fullPath'],
  apollo: {
    vulnerabilityScanners: {
      query() {
        return this.query;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        const { dataType } = DASHBOARD_QUERIES[this.dashboardType];
        const nodes = data[dataType]?.vulnerabilityScanners?.nodes;

        return nodes ? getFormattedScanners(nodes) : [];
      },
      result() {
        // This will trigger the emitter to refetch vulnerability list if the query string is present
        this.selectedOptions = this.querystringOptions;
      },
      error() {
        createAlert({
          message: TOOL_FILTER_ERROR,
        });
      },
      skip() {
        return !this.query;
      },
    },
  },
  data() {
    return {
      vulnerabilityScanners: [],
    };
  },
  computed: {
    // this computed property overrides the property in the SimpleFilter component
    options() {
      return this.vulnerabilityScanners;
    },
    query() {
      return DASHBOARD_QUERIES[this.dashboardType]?.query;
    },
    queryVariables() {
      const { fullPath } = DASHBOARD_QUERIES[this.dashboardType];

      return { fullPath: this[fullPath] };
    },
    isLoading() {
      return this.$apollo.queries.vulnerabilityScanners.loading;
    },
  },
  i18n: {
    disabledTooltip: s__('SecurityReports|Not available'),
  },
};
</script>

<template>
  <filter-body :name="filter.name" :selected-options="selectedOptionsOrAll" :loading="isLoading">
    <filter-item
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      data-testid="all"
      @click="deselectAllOptions"
    />
    <filter-item
      v-for="option in vulnerabilityScanners"
      :key="option.id"
      :is-checked="isSelected(option)"
      :text="option.name"
      :disabled="option.disabled"
      :tooltip="option.disabled ? $options.i18n.disabledTooltip : ''"
      :data-testid="`option:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
