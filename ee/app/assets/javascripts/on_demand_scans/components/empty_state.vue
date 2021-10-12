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
  props: {
    title: {
      type: String,
      required: false,
      default: s__('OnDemandScans|On-demand scans'),
    },
    text: {
      type: String,
      required: false,
      default: s__(
        'OnDemandScans|On-demand scans run outside of DevOps cycle and find vulnerabilities in your projects. %{learnMoreLinkStart}Lean more%{learnMoreLinkEnd}.',
      ),
    },
    noPrimaryButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    emptyStateProps() {
      const props = {
        title: this.title,
        svgPath: this.emptyStateSvgPath,
      };

      if (!this.noPrimaryButton) {
        props.primaryButtonText = this.$options.i18n.primaryButtonText;
        props.primaryButtonLink = this.newDastScanPath;
      }

      return props;
    },
  },
  i18n: {
    primaryButtonText: s__('OnDemandScans|New DAST scan'),
  },
};
</script>

<template>
  <gl-empty-state v-bind="emptyStateProps">
    <template #description>
      <gl-sprintf :message="text">
        <template #learnMoreLink="{ content }">
          <gl-link :href="helpPagePath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
