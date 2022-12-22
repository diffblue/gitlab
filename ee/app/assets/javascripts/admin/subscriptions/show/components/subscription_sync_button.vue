<script>
import { GlButton, GlPopover } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { SYNC_BUTTON_ID, syncButtonTexts } from '../constants';

export default {
  name: 'SubscriptionSyncButton',
  components: {
    GlButton,
    GlPopover,
  },
  computed: {
    ...mapState(['breakdown']),
    isDisabled() {
      return this.breakdown.hasAsyncActivity;
    },
  },
  methods: {
    ...mapActions(['syncSubscription']),
  },
  syncButtonTexts,
  SYNC_BUTTON_ID,
};
</script>
<template>
  <gl-button
    :id="$options.SYNC_BUTTON_ID"
    class="gl-absolute gl-mt-n2 gl-ml-2"
    category="tertiary"
    :title="$options.syncButtonTexts.syncSubscriptionButtonText"
    size="small"
    icon="retry"
    variant="default"
    :aria-label="$options.syncButtonTexts.syncSubscriptionButtonText"
    aria-live="polite"
    :disabled="isDisabled"
    @click="syncSubscription"
  >
    <gl-popover
      :css-classes="['gl-bg-white']"
      :content="$options.syncButtonTexts.syncSubscriptionTooltipText"
      :target="$options.SYNC_BUTTON_ID"
      placement="right"
    />
  </gl-button>
</template>
