<script>
import { GlBadge, GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  name: 'DastConfigurationHeader',
  components: {
    GlBadge,
    GlLink,
  },
  i18n: {
    notEnabledLabel: s__('DastConfig|Not enabled'),
    notEnabledText: s__('DastConfig|No previous scans found for this project'),
    enabledLabel: s__('DastConfig|Enabled'),
    enabledText: s__('DastConfig|Last scan triggered %{runTimeAgo} in pipeline '),
  },
  mixins: [timeagoMixin],
  props: {
    dastEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipelineId: {
      type: String,
      required: false,
      default: null,
    },
    pipelinePath: {
      type: String,
      required: false,
      default: null,
    },
    pipelineCreatedAt: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    badgeVariant() {
      return this.dastEnabled ? 'success' : 'neutral';
    },
    badgeText() {
      return this.dastEnabled
        ? this.$options.i18n.enabledLabel
        : this.$options.i18n.notEnabledLabel;
    },
    headerText() {
      return this.showPipelineLink ? this.enabledTextWithTime : this.$options.i18n.notEnabledText;
    },
    enabledTextWithTime() {
      return sprintf(this.$options.i18n.enabledText, {
        runTimeAgo: this.timeAgo,
      });
    },
    pipelineIdFormatted() {
      return `#${this.pipelineId}`;
    },
    dastUsedBefore() {
      return Boolean(this.pipelineCreatedAt);
    },
    timeAgo() {
      return this.timeFormatted(this.pipelineCreatedAt);
    },
    showPipelineLink() {
      return this.dastEnabled || this.dastUsedBefore;
    },
  },
};
</script>

<template>
  <div class="gl-py-5 gl-border-b gl-border-b-gray-100">
    <gl-badge :variant="badgeVariant" size="md">{{ badgeText }}</gl-badge>
    <span class="gl-ml-2">
      <span data-testid="dast-header-text">{{ headerText }}</span>
      <gl-link v-if="showPipelineLink" :href="pipelinePath" data-testid="help-page-link">
        {{ pipelineIdFormatted }}
      </gl-link>
    </span>
  </div>
</template>
