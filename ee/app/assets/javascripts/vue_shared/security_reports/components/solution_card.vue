<script>
import { s__ } from '~/locale';

export default {
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
  },
  computed: {
    solutionText() {
      return this.solution || (this.remediation && this.remediation.summary);
    },
    showCreateMergeRequestMsg() {
      return !this.hasMr && Boolean(this.remediation) && this.hasDownload;
    },
  },
  i18n: {
    createMergeRequestMsg: s__(
      'ciReport|Create a merge request to implement this solution, or download and apply the patch manually.',
    ),
  },
};
</script>
<template>
  <div v-if="solutionText" class="md my-4">
    <h3>{{ s__('ciReport|Solution') }}</h3>
    <div ref="solution-text">
      <p>
        {{ solutionText }}
      </p>
      <p v-if="showCreateMergeRequestMsg" class="gl-font-style-italic">
        {{ $options.i18n.createMergeRequestMsg }}
      </p>
    </div>
  </div>
</template>
