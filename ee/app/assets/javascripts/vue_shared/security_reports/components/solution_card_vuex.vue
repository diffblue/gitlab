<script>
import { GlIcon, GlCard } from '@gitlab/ui';

export default {
  name: 'SolutionCard',
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
    hasDownload: {
      type: Boolean,
      default: false,
      required: false,
    },
    hasMr: {
      type: Boolean,
      default: false,
      required: false,
    },
    isStandaloneVulnerability: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    solutionText() {
      return this.solution || (this.remediation && this.remediation.summary);
    },
    showCreateMergeRequestMsg() {
      return !this.hasMr && Boolean(this.remediation) && this.hasDownload;
    },
  },
};
</script>
<template>
  <gl-card
    v-if="solutionText || showCreateMergeRequestMsg"
    class="gl-my-6"
    :body-class="{ 'gl-p-0': !solutionText }"
    :footer-class="{ 'gl-border-0': !solutionText }"
  >
    <template v-if="solutionText" #default>
      <div class="gl-display-flex gl-align-items-center">
        <div
          class="col-auto gl-display-flex gl-align-items-center gl-justify-content-end gl-pl-0"
          :class="{ 'col-md-2': !isStandaloneVulnerability }"
        >
          <gl-icon class="gl-mr-5" name="bulb" />
          <strong>{{ s__('ciReport|Solution') }}:</strong>
        </div>
        <span class="flex-shrink-1 gl-pl-0" :class="{ 'col-md-10': !isStandaloneVulnerability }">{{
          solutionText
        }}</span>
      </div>
    </template>
    <template v-if="showCreateMergeRequestMsg" #footer>
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
