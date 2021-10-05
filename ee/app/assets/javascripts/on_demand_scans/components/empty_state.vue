<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  inject: ['newDastScanPath', 'helpPagePath', 'emptyStateSvgPath'],
  i18n: {
    title: s__('OnDemandScans|On-demand scans'),
    primaryButtonText: s__('OnDemandScans|New DAST scan'),
    text: s__(
      'OnDemandScans|On-demand scans run outside of DevOps cycle and find vulnerabilities in your projects. %{learnMoreLinkStart}Lean more%{learnMoreLinkEnd}.',
    ),
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="emptyStateSvgPath"
    :primary-button-text="$options.i18n.primaryButtonText"
    :primary-button-link="newDastScanPath"
  >
    <template #description>
      <gl-sprintf :message="$options.i18n.text">
        <template #learnMoreLink="{ content }">
          <gl-link :href="helpPagePath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
