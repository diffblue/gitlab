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
    remediation: {
      type: Object,
      default: null,
      required: false,
    },
    mergeRequest: {
      type: Object,
      default: null,
      required: false,
    },
  },
  computed: {
    solutionText() {
      return this.solution || this.remediation?.summary;
    },
    showCreateMergeRequestMessage() {
      return !this.hasMr && this.remediation?.diff?.length > 0;
    },
    hasMr() {
      return Boolean(this.mergeRequest?.id);
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
    <template v-if="showCreateMergeRequestMessage" #footer>
      <em class="gl-text-gray-500" data-testid="merge-request-solution">
        {{
          s__(
            'ciReport|Create a merge request to implement this solution, or download and apply the patch manually.',
          )
        }}
      </em>
    </template>
  </gl-card>
</template>
