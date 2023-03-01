<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__ } from '~/locale';

export default {
  directives: {
    SafeHtml,
  },
  props: {
    solutionText: {
      type: String,
      required: true,
    },
    canDownloadPatch: {
      type: Boolean,
      required: true,
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
  <div>
    <h3>{{ s__('ciReport|Solution') }}</h3>
    <p v-safe-html="solutionText" data-testid="solution-text"></p>
    <p v-if="canDownloadPatch" class="gl-font-style-italic" data-testid="create-mr-message">
      {{ $options.i18n.createMergeRequestMsg }}
    </p>
  </div>
</template>
