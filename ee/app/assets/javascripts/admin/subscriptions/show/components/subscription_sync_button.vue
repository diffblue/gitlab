<script>
import { GlButton, GlLoadingIcon, GlIcon, GlPopover } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { SYNC_BUTTON_ID, syncButtonTexts as i18n } from '../constants';

export default {
  name: 'SubscriptionSyncButton',
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
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
  i18n,
  SYNC_BUTTON_ID,
};
</script>
<template>
  <gl-button
    :id="$options.SYNC_BUTTON_ID"
    class="gl-absolute gl-mt-n2 gl-ml-2"
    category="tertiary"
    :title="$options.i18n.syncSubscriptionButtonText"
    size="small"
    variant="default"
    :aria-label="$options.i18n.syncSubscriptionButtonText"
    aria-live="polite"
    :disabled="isDisabled"
    @click="syncSubscription"
  >
    <gl-loading-icon v-if="isDisabled" />
    <template v-else>
      <gl-icon class="gl-button-icon" name="retry" />
      <gl-popover
        :css-classes="['gl-bg-white']"
        :content="$options.i18n.syncSubscriptionTooltipText"
        :target="$options.SYNC_BUTTON_ID"
        placement="right"
      />
    </template>
  </gl-button>
</template>
