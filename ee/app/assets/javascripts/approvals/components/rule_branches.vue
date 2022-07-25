<script>
import {
  ALL_BRANCHES,
  ALL_PROTECTED_BRANCHES,
} from 'ee/vue_shared/components/branches_selector/constants';

export default {
  props: {
    rule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    branchName() {
      const { protectedBranches, appliesToAllProtectedBranches } = this.rule;
      const [protectedBranch] = protectedBranches || [];

      if (appliesToAllProtectedBranches) {
        return ALL_PROTECTED_BRANCHES.name;
      }

      return protectedBranch?.name || ALL_BRANCHES.name;
    },
    shouldUseMonospace() {
      return this.rule.protectedBranches?.length > 0 && !this.rule.appliesToAllProtectedBranches;
    },
  },
};
</script>

<template>
  <div :class="{ monospace: shouldUseMonospace }">{{ branchName }}</div>
</template>
