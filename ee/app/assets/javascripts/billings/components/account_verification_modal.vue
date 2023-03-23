<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import Zuora from 'ee/billings/components/zuora_simple.vue';

export const IFRAME_MINIMUM_HEIGHT = 350;
const i18n = Object.freeze({
  title: s__('Billings|Validate user account'),
  description: s__(`
Billings|To use free CI/CD minutes on shared runners, you’ll need to validate your account with a credit card. This is required to discourage and reduce abuse on GitLab infrastructure.
%{strongStart}GitLab will not charge your card, it will only be used for validation.%{strongEnd}`),
});

export default {
  components: {
    GlModal,
    GlSprintf,
    Zuora,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    iframeUrl: {
      type: String,
      required: true,
    },
    allowedOrigin: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hasLoadError: false,
      paymentFormId: window.gon?.payment_validation_form_id,
    };
  },
  computed: {
    actionPrimaryProps() {
      return {
        text: s__('Billings|Validate account'),
        attributes: {
          variant: 'confirm',
          disabled: this.hasLoadError,
        },
      };
    },
    currentUserId() {
      return window.gon.current_user_id;
    },
  },
  methods: {
    submit(e) {
      e.preventDefault();

      this.$refs.zuora.submit();
    },
    handleLoadError() {
      this.hasLoadError = true;
    },
  },
  i18n,
  iframeHeight: IFRAME_MINIMUM_HEIGHT,
};
</script>

<template>
  <gl-modal
    modal-id="credit-card-verification-modal"
    :visible="visible"
    :title="$options.i18n.title"
    :action-primary="actionPrimaryProps"
    @primary="submit"
    @change="$emit('change', $event)"
  >
    <p>
      <gl-sprintf :message="$options.i18n.description">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </p>
    <zuora
      ref="zuora"
      :current-user-id="currentUserId"
      :initial-height="$options.iframeHeight"
      :iframe-url="iframeUrl"
      :allowed-origin="allowedOrigin"
      :payment-form-id="paymentFormId"
      @success="$emit('success')"
      @load-error="handleLoadError"
    />
  </gl-modal>
</template>
