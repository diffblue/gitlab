<script>
import { GlDrawer, GlIcon, GlBadge } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpCenterState } from '~/super_sidebar/constants';

export default {
  name: 'TanukiBotChatApp',
  i18n: {
    tanukiBot: s__('TanukiBot|Tanuki Bot'),
    experiment: __('Experiment'),
  },
  components: {
    GlIcon,
    GlDrawer,
    GlBadge,
  },
  data() {
    return {
      helpCenterState,
    };
  },
  methods: {
    closeDrawer() {
      this.helpCenterState.showTanukiBotChatDrawer = false;
    },
  },
};
</script>

<template>
  <section>
    <gl-drawer
      data-testid="tanuki-bot-chat-drawer"
      class="tanuki-bot-chat-drawer gl-reset-line-height"
      :z-index="1000"
      :open="helpCenterState.showTanukiBotChatDrawer"
      @close="closeDrawer"
    >
      <template #title>
        <span class="gl-display-flex gl-align-items-center">
          <gl-icon name="tanuki" class="gl-text-orange-500" />
          <h3 class="gl-my-0 gl-mx-3">{{ $options.i18n.tanukiBot }}</h3>
          <gl-badge variant="muted">{{ $options.i18n.experiment }}</gl-badge>
        </span>
      </template>
    </gl-drawer>
    <div
      v-if="helpCenterState.showTanukiBotChatDrawer"
      class="modal-backdrop tanuki-bot-backdrop"
      data-testid="tanuki-bot-chat-drawer-backdrop"
      @click="closeDrawer"
    ></div>
  </section>
</template>
