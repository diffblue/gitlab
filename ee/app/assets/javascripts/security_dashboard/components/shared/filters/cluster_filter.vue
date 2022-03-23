<script>
import createFlash from '~/flash';
import { s__ } from '~/locale';
import getClusterAgentsQuery from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';
import SimpleFilter from './simple_filter.vue';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';

export default {
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
          message: s__('SecurityOrchestration|Failed to load cluster agents.'),
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
      // This is the object used to update the GraphQL query.
      if (this.isNoOptionsSelected) {
        return { clusterAgentId: [] };
      }

      const gids = this.selectedOptions.map((a) => a.gid);

      return { clusterAgentId: gids };
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
      :text="option.id"
      :data-testid="`option:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
