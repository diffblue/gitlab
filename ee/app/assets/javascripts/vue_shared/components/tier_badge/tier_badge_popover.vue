<script>
import { GlPopover, GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import Tracking from '~/tracking';

const GROUP_SOURCE_TYPE = 'Group';

export default {
  name: 'TierBadgePopover',
  components: {
    GlPopover,
    GlButton,
  },
  mixins: [Tracking.mixin({ experiment: 'tier_badge', label: 'tier-badge' })],
  inject: ['primaryCtaLink', 'secondaryCtaLink', 'sourceType'],
  props: {
    popoverId: {
      type: String,
      required: true,
    },
    tier: {
      type: String,
      required: true,
    },
    showIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    copyText() {
      const { groupCopyStart, projectCopyStart, copyEnd } = this.$options.i18n;

      if (this.sourceType === GROUP_SOURCE_TYPE) {
        return sprintf(groupCopyStart, { tier: this.tier, copyEnd });
      }

      return sprintf(projectCopyStart, { tier: this.tier, copyEnd });
    },
  },
  methods: {
    trackPrimaryCta() {
      this.track('click_start_trial_button');
    },
    trackSecondaryCta() {
      this.track('click_compare_plans_button');
    },
  },
  i18n: {
    title: s__('TierBadgePopover|Enhance team productivity'),
    groupCopyStart: s__(
      `TierBadgePopover|This group and all its related projects use the %{tier} GitLab tier. %{copyEnd}`,
    ),
    projectCopyStart: s__(`TierBadgePopover|This project uses the %{tier} GitLab tier. %{copyEnd}`),
    copyEnd: s__(
      'TierBadgePopover|Want to enhance team productivity and access advanced features like Merge Approvals, Push rules, Epics, Code Review Analytics, and Container Scanning? Try all GitLab has to offer for free for 30 days. No credit card required.',
    ),
    primaryCtaText: s__('TierBadgePopover|Start a free trial'),
    secondaryCtaText: s__('TierBadgePopover|Explore paid plans'),
  },
};
</script>

<template>
  <gl-popover :target="popoverId" placement="bottom" :css-classes="['tier-badge-popover']">
    <template #title>
      <h5><span v-if="showIcon">🚀</span> {{ $options.i18n.title }}</h5>
    </template>

    <div class="gl-mb-3">
      {{ copyText }}
    </div>

    <gl-button
      :href="primaryCtaLink"
      class="my-1 w-100"
      variant="info"
      data-testid="tier-badge-popover-primary-cta"
      @click="trackPrimaryCta"
      >{{ $options.i18n.primaryCtaText }}</gl-button
    >
    <gl-button
      :href="secondaryCtaLink"
      class="my-1 w-100"
      variant="info"
      category="secondary"
      data-testid="tier-badge-popover-secondary-cta"
      @click="trackSecondaryCta"
      >{{ $options.i18n.secondaryCtaText }}</gl-button
    >
  </gl-popover>
</template>

<style>
.tier-badge-popover .popover-body {
  border-top: 1px solid #dbdbdb;
}
</style>
