<script>
import { __ } from '~/locale';

export default {
  props: {
    rule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    branchName() {
      const { protectedBranches } = this.rule;
      const [protectedBranch] = protectedBranches || [];
      return protectedBranch?.name || __('All branches');
    },
    isAllBranches() {
      return !this.rule.protectedBranches?.length;
    },
  },
};
</script>

<template>
  <div :class="{ monospace: !isAllBranches }">{{ branchName }}</div>
</template>
