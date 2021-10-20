<script>
import PoliciesHeader from './policies_header.vue';
import PoliciesList from './policies_list.vue';

export default {
  components: {
    PoliciesHeader,
    PoliciesList,
  },
  data() {
    return {
      shouldUpdatePolicyList: false,
    };
  },
  methods: {
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
      :should-update-policy-list="shouldUpdatePolicyList"
      @update-policy-list="handleUpdatePolicyList"
    />
  </div>
</template>
