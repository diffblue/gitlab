<script>
import { GlSprintf } from '@gitlab/ui';
import { i18n } from './i18n';

export default {
  components: {
    GlSprintf,
  },
  i18n,
  props: {
    scanner: {
      type: String,
      required: false,
      default: undefined,
    },
    totalNewVulnerabilities: {
      type: Number,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    error: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div>
    <span v-if="isLoading">{{ $options.i18n.loading }}</span>
    <gl-sprintf v-else-if="error" :message="$options.i18n.loadingError">
      <template #scanner>{{ scanner }}</template>
    </gl-sprintf>
    <gl-sprintf v-else-if="!totalNewVulnerabilities" :message="$options.i18n.noNewVulnerabilities">
      <template #scanner>{{ scanner || $options.i18n.securityScanning }}</template>
    </gl-sprintf>
    <gl-sprintf v-else :message="$options.i18n.newVulnerabilities">
      <template #scanner>{{ scanner || $options.i18n.securityScanning }}</template>
      <template #number
        ><strong>{{ totalNewVulnerabilities }}</strong></template
      >
      <template #vulnStr>{{
        n__('vulnerability', 'vulnerabilities', totalNewVulnerabilities)
      }}</template>
    </gl-sprintf>
  </div>
</template>
