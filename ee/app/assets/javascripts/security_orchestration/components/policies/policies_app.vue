<script>
import PoliciesHeader from './policies_header.vue';
import PoliciesList from './policies_list.vue';

export default {
  components: {
    PoliciesHeader,
    PoliciesList,
  },
  inject: ['assignedPolicyProject'],
  data() {
    return {
      hasPolicyProject: Boolean(this.assignedPolicyProject?.id),
      shouldUpdatePolicyList: false,
    };
  },
  methods: {
    handleUpdatePolicyList({ hasPolicyProject, shouldUpdatePolicyList = false }) {
      if (hasPolicyProject !== undefined) {
        this.hasPolicyProject = hasPolicyProject;
      }

      this.shouldUpdatePolicyList = shouldUpdatePolicyList;
    },
  },
};
</script>
<template>
  <div>
    <policies-header @update-policy-list="handleUpdatePolicyList" />
    <policies-list
      :has-policy-project="hasPolicyProject"
      :should-update-policy-list="shouldUpdatePolicyList"
      @update-policy-list="handleUpdatePolicyList"
    />
  </div>
</template>
