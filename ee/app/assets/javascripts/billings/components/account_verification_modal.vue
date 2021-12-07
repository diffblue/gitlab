<script>
import { GlAlert, GlLoadingIcon, GlModal, GlSprintf } from '@gitlab/ui';
import { objectToQuery } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';

const IFRAME_QUERY = Object.freeze({
  enable_submit: false,
  user_id: null,
});
// 350 is the mininum required height to get all iframe inputs visible
const IFRAME_MINIMUM_HEIGHT = 350;
const i18n = Object.freeze({
  title: s__('Billings|Validate user account'),
  description: s__(`
Billings|To use free pipeline minutes on shared runners, you’ll need to validate your account with a credit or debit card. This is required to discourage and reduce abuse on GitLab infrastructure.
%{strongStart}GitLab will not charge your card, it will only be used for validation.%{strongEnd}`),
  iframeNotSupported: __('Your browser does not support iFrames'),
  actions: {
    primary: {
      text: s__('Billings|Validate account'),
    },
  },
});

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
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
  data() {
    return {
      error: null,
      isLoading: true,
      isAlertDismissed: true,
    };
  },
  computed: {
    iframeSrc() {
      const query = { ...IFRAME_QUERY, user_id: gon.current_user_id };

      return `${this.iframeUrl}?${objectToQuery(query)}`;
    },
    iframeHeight() {
      return IFRAME_MINIMUM_HEIGHT * window.devicePixelRatio;
    },
    shouldShowAlert() {
      return this.error && !this.isAlertDismissed;
    },
  },
  destroyed() {
    window.removeEventListener('message', this.handleFrameMessages, true);
  },
  methods: {
    submit(e) {
      e.preventDefault();

      this.error = null;
      this.isLoading = true;
      this.isAlertDismissed = true;

      this.$refs.zuora.contentWindow.postMessage('submit', this.allowedOrigin);
    },
    show() {
      this.isLoading = true;
      this.$refs.modal.show();
    },
    hide() {
      this.error = null;
      this.$refs.modal.hide();
    },
    handleFrameLoaded() {
      this.isLoading = false;
      window.addEventListener('message', this.handleFrameMessages, true);
    },
    handleFrameMessages(event) {
      if (!this.isEventAllowedForOrigin(event)) {
        return;
      }

      if (event.data.success) {
        this.$emit('success');
      } else if (parseInt(event.data.code, 10) > 6) {
        // 0-6 error codes mean client-side validation error after submit,
        // no needs to reload the iframe and emit the failure event
        this.error = event.data.msg;
        this.isAlertDismissed = false;
        window.removeEventListener('message', this.handleFrameMessages, true);
        this.$refs.zuora.src = this.iframeSrc;
        this.$emit('failure', { msg: this.error });
      }

      this.isLoading = false;
    },
    isEventAllowedForOrigin(event) {
      try {
        const url = new URL(event.origin);

        return url.origin === this.allowedOrigin;
      } catch {
        return false;
      }
    },
    handleAlertDismiss() {
      this.isAlertDismissed = true;
    },
  },
  i18n,
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

    <gl-alert v-if="shouldShowAlert" variant="danger" @dismiss="handleAlertDismiss">{{
      error
    }}</gl-alert>
    <gl-loading-icon v-if="isLoading" size="lg" />
    <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
    <iframe
      ref="zuora"
      :src="iframeSrc"
      style="border: none"
      width="100%"
      :height="iframeHeight"
      @load="handleFrameLoaded"
    >
      <p>{{ $options.i18n.iframeNotSupported }}</p>
    </iframe>
    <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
  </gl-modal>
</template>
