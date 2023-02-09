<script>
import { createAlert } from '~/flash';
import getClusterAgentsQuery from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';
import { CLUSTER_FILTER_ERROR } from './constants';
import SimpleFilter from './simple_filter.vue';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';

export default {
  components: { FilterBody, FilterItem },
  extends: SimpleFilter,
  apollo: {
    clusterAgents: {
      query: getClusterAgentsQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      update: (data) =>
        data.project?.clusterAgents?.nodes.map((c) => ({
          id: c.name,
          name: c.name,
          gid: c.id,
        })) || [],
      error() {
        createAlert({
          message: CLUSTER_FILTER_ERROR,
        });
      },
    },
  },
  inject: ['projectFullPath'],
  data() {
    return {
      clusterAgents: [],
    };
  },
  computed: {
    filterObject() {
      // This is passed to the vulnerability list's GraphQL query as a variable.
      return { clusterAgentId: this.selectedOptions.map((x) => x.gid) };
    },
    // this computed property overrides the property in the SimpleFilter component
    options() {
      return this.clusterAgents;
    },
    isLoading() {
      return this.$apollo.queries.clusterAgents.loading;
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
  <filter-body :name="filter.name" :selected-options="selectedOptionsOrAll" :loading="isLoading">
    <filter-item
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      data-testid="all"
      @click="deselectAllOptions"
    />
    <filter-item
      v-for="option in clusterAgents"
      :key="option.id"
      :is-checked="isSelected(option)"
      :text="option.id"
      :data-testid="`option:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
