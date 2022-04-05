<script>
import createFlash from '~/flash';
import getClusterAgentsQuery from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';
import { CLUSTER_FILTER_ERROR } from './constants';
import SimpleFilter from './simple_filter.vue';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';

export default {
  includeAllInUrl: false,
  urlField: 'name',
  components: { FilterBody, FilterItem },
  extends: SimpleFilter,
  apollo: {
    clusterAgents: {
      loadingKey: 'isLoading',
      query: getClusterAgentsQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      update: (data) => data.project?.clusterAgents?.nodes || [],
      error() {
        createFlash({
          message: CLUSTER_FILTER_ERROR,
        });
      },
    },
  },
  inject: ['projectFullPath'],
  data() {
    return {
      isLoading: 0,
      clusterAgents: [],
    };
  },
  computed: {
    options() {
      return this.clusterAgents;
    },
    filterObject() {
      // This is passed to the vulnerability list's GraphQL query as a variable.
      return { clusterAgentId: this.selectedOptions.map((x) => x.id) };
    },
  },
  watch: {
    options() {
      this.processQuerystringIds();
    },
  },
};
</script>

<template>
  <filter-body
    :name="filter.name"
    :selected-options="selectedOptionsOrAll"
    :show-search-box="false"
    :loading="Boolean(isLoading)"
  >
    <filter-item
      v-if="filter.allOption"
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      data-testid="all"
      @click="deselectAllOptions"
    />
    <filter-item
      v-for="option in options"
      :key="option.id"
      :is-checked="isSelected(option)"
      :text="option.name"
      :data-testid="`option:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
