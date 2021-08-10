<script>
import { mapActions } from 'vuex';
import NoEnvironmentEmptyState from '../no_environment_empty_state.vue';
import PoliciesHeader from './policies_header.vue';
import PoliciesList from './policies_list.vue';

export default {
  components: {
    PoliciesHeader,
    PoliciesList,
    NoEnvironmentEmptyState,
  },
  inject: ['defaultEnvironmentId'],
  data() {
    return {
      // We require the project to have at least one available environment.
      // An invalid default environment id means there there are no available
      // environments, therefore infrastructure cannot be set up. A valid default
      // environment id only means that infrastructure *might* be set up.
      shouldFetchEnvironment: this.isValidEnvironmentId(this.defaultEnvironmentId),
    };
  },
  created() {
    if (this.shouldFetchEnvironment) {
      this.setCurrentEnvironmentId(this.defaultEnvironmentId);
      this.fetchEnvironments();
    }
  },
  methods: {
    ...mapActions('threatMonitoring', ['fetchEnvironments', 'setCurrentEnvironmentId']),

    isValidEnvironmentId(id) {
      return Number.isInteger(id) && id >= 0;
    },
  },
};
</script>
<template>
  <div>
    <policies-header />
    <no-environment-empty-state v-if="!shouldFetchEnvironment" />
    <policies-list v-else />
  </div>
</template>
