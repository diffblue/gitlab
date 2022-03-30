<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { HELP_PAGE_PATH } from '../constants';

export default {
  HELP_PAGE_PATH,
  components: {
    GlEmptyState,
    GlSprintf,
    GlLink,
  },
  inject: ['newDastScanPath', 'emptyStateSvgPath'],
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
        'OnDemandScans|On-demand scans run outside of DevOps cycle and find vulnerabilities in your projects. %{learnMoreLinkStart}Learn more%{learnMoreLinkEnd}.',
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
    primaryButtonText: s__('OnDemandScans|New scan'),
  },
};
</script>

<template>
  <gl-empty-state v-bind="emptyStateProps">
    <template #description>
      <gl-sprintf :message="text">
        <template #learnMoreLink="{ content }">
          <gl-link :href="$options.HELP_PAGE_PATH">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
