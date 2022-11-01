<script>
import { GlSprintf } from '@gitlab/ui';
import { CRITICAL, HIGH } from '~/vulnerabilities/constants';
import { i18n } from './i18n';

export default {
  components: {
    GlSprintf,
  },
  i18n,
  props: {
    highlights: {
      type: Object,
      required: true,
      validate: (highlights) =>
        [CRITICAL, HIGH, 'other'].every(
          (requiredField) => typeof highlights[requiredField] !== 'undefined',
        ),
    },
  },
  computed: {
    criticalSeverity() {
      return this.highlights[CRITICAL];
    },
    highSeverity() {
      return this.highlights[HIGH];
    },
    otherSeverity() {
      return this.highlights.other;
    },
  },
};
</script>

<template>
  <div class="gl-font-sm">
    <gl-sprintf :message="$options.i18n.highlights">
      <template #critical="{ content }"
        ><strong class="gl-text-red-800">{{ criticalSeverity }} {{ content }}</strong></template
      >
      <template #high="{ content }"
        ><strong class="gl-text-red-600">{{ highSeverity }} {{ content }}</strong></template
      >
      <template #other="{ content }"
        ><strong>{{ otherSeverity }} {{ content }}</strong></template
      >
    </gl-sprintf>
  </div>
</template>
