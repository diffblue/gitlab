<script>
import createFlash from '~/flash';
import projectScannersQuery from 'ee/security_dashboard/graphql/queries/project_specific_scanners.query.graphql';
import { getFormattedScanners } from 'ee/security_dashboard/helpers';
import SimpleFilter from './simple_filter.vue';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import { TOOL_FILTER_ERROR } from './constants';

export default {
  name: 'ToolFilter',
  components: { FilterBody, FilterItem },
  extends: SimpleFilter,
  inject: ['projectFullPath'],
  apollo: {
    vulnerabilityScanners: {
      loadingKey: 'isLoading',
      query: projectScannersQuery,
      variables() {
        return {
          fullPath: this.projectFullPath,
        };
      },
      update(data) {
        const nodes = data?.project?.vulnerabilityScanners?.nodes;
        return nodes ? getFormattedScanners(nodes) : [];
      },
      error() {
        createFlash({
          message: TOOL_FILTER_ERROR,
        });
      },
    },
  },
  data() {
    return {
      isLoading: 0,
      vulnerabilityScanners: [],
    };
  },
  computed: {
    // this computed property overrides the property in the SimpleFilter component
    options() {
      return this.vulnerabilityScanners;
    },
  },
};
</script>

<template>
  <filter-body
    :name="filter.name"
    :selected-options="selectedOptionsOrAll"
    :loading="Boolean(isLoading)"
  >
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
      :data-testid="`option:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
