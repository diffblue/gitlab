<script>
import { GlSprintf } from '@gitlab/ui';
import { i18n } from './i18n';

export const MAX_NEW_VULNERABILITIES = 25;

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
    showAtLeastHint: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    newVulnerabilitiesMessage() {
      return this.totalNewVulnerabilities >= MAX_NEW_VULNERABILITIES && this.showAtLeastHint
        ? i18n.newVulnerabilitiesAtLeast
        : i18n.newVulnerabilities;
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
    <gl-sprintf v-else :message="newVulnerabilitiesMessage">
      <template #scanner>{{ scanner || $options.i18n.securityScanning }}</template>
      <template #atleast="{ content }"
        ><strong>{{ content }}</strong></template
      >
      <template #number
        ><strong>{{ totalNewVulnerabilities }}</strong></template
      >
      <template #vulnStr>{{
        n__('vulnerability', 'vulnerabilities', totalNewVulnerabilities)
      }}</template>
    </gl-sprintf>
  </div>
</template>
