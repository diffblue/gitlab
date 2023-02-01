<script>
import { mapState } from 'vuex';
import { GlButton, GlModal } from '@gitlab/ui';
import Tracking from '~/tracking';

import {
  MODAL_BODY,
  MODAL_CHAT_SALES_BTN,
  MODAL_CLOSE_BTN,
  MODAL_START_TRIAL_BTN,
  MODAL_TIMEOUT,
  MODAL_TITLE,
  TRACKING_EVENTS,
} from '../constants';

export default {
  components: { GlModal, GlButton },
  mixins: [Tracking.mixin({ experiment: 'cart_abandonment_modal' })],
  data() {
    return {
      visible: false,
    };
  },
  computed: {
    ...mapState(['isTrial', 'newTrialRegistrationPath']),
  },
  mounted() {
    setTimeout(() => {
      this.visible = true;
      this.trackPageAction('modalRendered');
    }, MODAL_TIMEOUT);
  },
  methods: {
    trackPageAction(eventName) {
      const { action, ...options } = TRACKING_EVENTS[eventName];
      this.track(action, { ...options });
    },
    cancel() {
      this.visible = false;
      this.trackPageAction('cancel');
    },
  },
  i18n: {
    modalTitle: MODAL_TITLE,
    modalCloseBtn: MODAL_CLOSE_BTN,
    modalChatSalesBtn: MODAL_CHAT_SALES_BTN,
    modalStartTrialBtn: MODAL_START_TRIAL_BTN,
    modalBody: MODAL_BODY,
  },
};
</script>
<template>
  <gl-modal
    modal-id="subscription-modal"
    size="sm"
    :visible="visible"
    @close="trackPageAction('dismiss')"
  >
    <template #modal-title>
      {{ $options.i18n.modalTitle }}
      <gl-emoji data-name="thinking" />
    </template>

    {{ $options.i18n.modalBody }}

    <template #modal-footer>
      <gl-button data-testid="modal-close-btn" @click="cancel">
        {{ $options.i18n.modalCloseBtn }}
      </gl-button>

      <gl-button
        variant="confirm"
        category="secondary"
        data-testid="talk-to-sales-btn"
        href="https://about.gitlab.com/sales"
        @click="trackPageAction('talkToSales')"
      >
        {{ $options.i18n.modalChatSalesBtn }}
      </gl-button>

      <gl-button
        v-if="!isTrial"
        variant="confirm"
        data-testid="start-free-trial-btn"
        :href="newTrialRegistrationPath"
        @click="trackPageAction('startFreeTrial')"
      >
        {{ $options.i18n.modalStartTrialBtn }}
      </gl-button>
    </template>
  </gl-modal>
</template>
