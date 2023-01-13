<script>
import { GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import TierBadgePopover from './tier_badge_popover.vue';

export default {
  components: {
    GlBadge,
    TierBadgePopover,
  },
  props: {
    tier: {
      type: String,
      required: false,
      default: s__('TierBadge|Free'),
    },
  },
  popoverTriggerId: 'tier-badge-trigger-id',
};
</script>
<template>
  <span class="gl-display-flex gl-align-items-center gl-ml-2">
    <gl-badge :id="$options.popoverTriggerId" data-testid="tier-badge" variant="tier" size="md">
      {{ tier }}
    </gl-badge>
    <tier-badge-popover
      :popover-id="$options.popoverTriggerId"
      triggers="hover focus manual"
      :tier="tier"
      :show-icon="true"
    />
  </span>
</template>
