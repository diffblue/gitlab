<script>
import { GlLink } from '@gitlab/ui';
import { decimalBytes } from '~/lib/utils/unit_format';
import { s__ } from '~/locale';

export default {
  components: {
    GlLink,
  },
  props: {
    corpus: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    latestJob: s__('CorpusManagement|Latest Job:'),
  },
  computed: {
    fileSize() {
      return decimalBytes(this.corpus.size);
    },
    jobUrl() {
      /*
       * TODO: Replace with relative path when we complete backend
       * https://gitlab.com/gitlab-org/gitlab/-/issues/321618
       */
      return `https://www.gitlab.com/${this.corpus.latestJobPath}`;
    },
    jobPath() {
      return this.corpus.latestJobPath;
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-text-gray-900" data-testid="corpus-name">
      {{ corpus.name }}
      <span class="gl-text-gray-500" data-testid="file-size">({{ fileSize }})</span>
    </div>
    <div data-testid="latest-job">
      {{ this.$options.i18n.latestJob }}
      <gl-link v-if="jobPath" class="gl-display-inline-block" :href="jobUrl" target="_blank">
        {{ jobPath }}
      </gl-link>
      <template v-else>-</template>
    </div>
  </div>
</template>
