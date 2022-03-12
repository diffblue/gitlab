<script>
import getClusterAgentsQuery from 'ee/security_dashboard/graphql/queries/cluster_agents.query.graphql';
import SimpleFilter from './simple_filter.vue';

export default {
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
  components: {
    SimpleFilter,
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
      selectedOptions: undefined,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.clusterAgents.loading;
    },
  },
  methods: {
    emitFilterChanged(data) {
      this.$emit('filter-changed', data);
    },
  },
};
</script>

<template>
  <simple-filter
    v-if="!isLoading"
    :key="filter.id"
    :filter="filter"
    :custom-options="clusterAgents"
    :data-testid="filter.id"
    @filter-changed="emitFilterChanged"
  />
</template>
