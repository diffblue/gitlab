<script>
import { mapActions } from 'vuex';
import { isValidEnvironmentId } from '../../utils';
import PoliciesHeader from './policies_header.vue';
import PoliciesList from './policies_list.vue';

export default {
  components: {
    PoliciesHeader,
    PoliciesList,
  },
  inject: ['defaultEnvironmentId'],
  data() {
    return {
      // We require the project to have at least one available environment.
      // An invalid default environment id means there there are no available
      // environments, therefore infrastructure cannot be set up. A valid default
      // environment id only means that infrastructure *might* be set up.
      shouldFetchEnvironment: isValidEnvironmentId(this.defaultEnvironmentId),
      shouldUpdatePolicyList: false,
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
    handleUpdatePolicyList(val) {
      this.shouldUpdatePolicyList = val;
    },
  },
};
</script>
<template>
  <div>
    <policies-header @update-policy-list="handleUpdatePolicyList" />
    <policies-list
      :has-environment="shouldFetchEnvironment"
      :should-update-policy-list="shouldUpdatePolicyList"
      @update-policy-list="handleUpdatePolicyList"
    />
  </div>
</template>
