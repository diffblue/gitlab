<script>
import getClusterAgentsQuery from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';
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
      update: (data) => data.project?.clusterAgents?.nodes || [],
    },
  },
  inject: ['projectFullPath'],
  props: {
    filter: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      clusterAgents: [],
    };
  },
  computed: {
    options() {
      return this.clusterAgents;
    },
    isLoading() {
      return this.$apollo.queries.clusterAgents.loading;
    },
    filterObject() {
      // This is the object used to update the GraphQL query.
      if (this.isNoOptionsSelected) {
        return { clusterAgentId: [] };
      }

      const gids = this.selectedOptions.map((a) => a.gid);

      return { clusterAgentId: gids };
    },
  },
};
</script>

<template>
  <filter-body
    :name="filter.name"
    :selected-options="selectedOptionsOrAll"
    :show-search-box="false"
    :loading="isLoading"
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
      :text="option.id"
      :data-testid="`option:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
