<script>
import { GlIcon, GlCard } from '@gitlab/ui';

export default {
  components: { GlIcon, GlCard },
  props: {
    solution: {
      type: String,
      default: '',
      required: false,
    },
  },
  computed: {
    solutionText() {
      // Note: this will be expanded for remediation in a follow-up issue
      return this.solution;
    },
  },
};
</script>

<template>
  <gl-card v-if="solutionText" class="gl-my-6">
    <template v-if="solutionText" #default>
      <div class="gl-display-flex gl-align-items-center">
        <div class="gl-pr-5 gl-display-flex gl-align-items-center gl-justify-content-end gl-pl-0">
          <gl-icon class="gl-mr-5" name="bulb" />
          <strong data-testid="solution-title">{{ s__('ciReport|Solution') }}:</strong>
        </div>
        <span class="flex-shrink-1 gl-pl-0" data-testid="solution-text">{{ solutionText }}</span>
      </div>
    </template>
  </gl-card>
</template>
