<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import Zuora from './zuora.vue';

const IFRAME_MINIMUM_HEIGHT = 350;
const i18n = Object.freeze({
  title: s__('Billings|Validate user account'),
  description: s__(`
Billings|To use free CI/CD minutes on shared runners, you’ll need to validate your account with a credit card. This is required to discourage and reduce abuse on GitLab infrastructure.
%{strongStart}GitLab will not charge your card, it will only be used for validation.%{strongEnd}`),
  actions: {
    primary: {
      text: s__('Billings|Validate account'),
    },
  },
});

export default {
  components: {
    GlModal,
    GlSprintf,
    Zuora,
  },
  props: {
    iframeUrl: {
      type: String,
      required: true,
    },
    allowedOrigin: {
      type: String,
      required: true,
    },
  },
  methods: {
    submit(e) {
      e.preventDefault();

      this.$refs.zuora.submit();
    },
    show() {
      this.$refs.modal.show();
    },
    hide() {
      this.$refs.modal.hide();
    },
  },
  i18n,
  iframeHeight: IFRAME_MINIMUM_HEIGHT,
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="credit-card-verification-modal"
    :title="$options.i18n.title"
    :action-primary="$options.i18n.actions.primary"
    @primary="submit"
  >
    <p>
      <gl-sprintf :message="$options.i18n.description">
        <template #strong="{ content }"
          ><strong>{{ content }}</strong></template
        >
      </gl-sprintf>
    </p>
    <zuora
      ref="zuora"
      :initial-height="$options.iframeHeight"
      :iframe-url="iframeUrl"
      :allowed-origin="allowedOrigin"
      @success="$emit('success')"
    />
  </gl-modal>
</template>
