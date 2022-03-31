<script>
import { GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { objectToQuery } from '~/lib/utils/url_utility';

const ZUORA_CLIENT_ERROR_HEIGHT = 15;
const IFRAME_QUERY = Object.freeze({
  enable_submit: false,
  user_id: null,
  location: null,
});

const I18N = {
  iframeNotSupported: __('Your browser does not support iFrames'),
};

export default {
  components: {
    GlLoadingIcon,
    GlAlert,
  },
  mixins: [Tracking.mixin({ category: 'Zuora_cc' })],
  props: {
    iframeUrl: {
      type: String,
      required: true,
    },
    allowedOrigin: {
      type: String,
      required: true,
    },
    initialHeight: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      error: null,
      isLoading: true,
      iframeHeight: this.initialHeight,
    };
  },
  computed: {
    iframeSrc() {
      const query = {
        ...IFRAME_QUERY,
        user_id: gon.current_user_id,
        location: btoa(window.location.href),
      };

      return `${this.iframeUrl}?${objectToQuery(query)}`;
    },
  },
  watch: {
    isLoading(value) {
      this.$emit('loading', value);
    },
  },
  destroyed() {
    window.removeEventListener('message', this.handleFrameMessages, true);
  },
  methods: {
    handleFrameLoaded() {
      this.track('iframe_loaded');
      this.isLoading = false;
      window.addEventListener('message', this.handleFrameMessages, true);
    },
    submit() {
      this.error = null;
      this.isLoading = true;
      this.iframeHeight = this.initialHeight;

      this.$refs.zuora.contentWindow.postMessage('submit', this.allowedOrigin);
    },
    handleFrameMessages(event) {
      if (!this.isEventAllowedForOrigin(event)) {
        return;
      }

      if (event.data.success) {
        this.track('success');
        this.$emit('success');
      } else if (parseInt(event.data.code, 10) < 7) {
        // 0-6 error codes mean client-side validation error after submit,
        // no need to reload the iframe and emit the failure event
        // Add a 15px height to the iframe to accomodate the error message
        this.iframeHeight += ZUORA_CLIENT_ERROR_HEIGHT;
        this.track('client_error', { property: event.data.msg });
      } else if (parseInt(event.data.code, 10) > 6) {
        this.track('error', { property: event.data.msg });
        this.error = event.data.msg;
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
  },
  i18n: I18N,
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = null">
      {{ error }}
    </gl-alert>
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
  </div>
</template>
