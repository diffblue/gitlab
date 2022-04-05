<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import Tracking from '~/tracking';
import { ZUORA_SCRIPT_URL, ZUORA_IFRAME_OVERRIDE_PARAMS } from 'ee/subscriptions/constants';

export default {
  components: {
    GlLoadingIcon,
  },
  mixins: [Tracking.mixin({ category: 'Zuora_cc' })],
  props: {
    active: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['success', 'error'],
  computed: {
    ...mapState([
      'paymentFormParams',
      'paymentMethodId',
      'creditCardDetails',
      'isLoadingPaymentMethod',
    ]),
  },
  watch: {
    // The Zuora script has loaded and the parameters for rendering the iframe have been fetched.
    paymentFormParams() {
      this.renderZuoraIframe();
    },
  },
  mounted() {
    this.loadZuoraScript();
  },
  methods: {
    ...mapActions([
      'startLoadingZuoraScript',
      'fetchPaymentFormParams',
      'zuoraIframeRendered',
      'paymentFormSubmitted',
    ]),
    loadZuoraScript() {
      this.startLoadingZuoraScript();

      if (!window.Z) {
        const zuoraScript = document.createElement('script');
        zuoraScript.type = 'text/javascript';
        zuoraScript.async = true;
        zuoraScript.onload = this.fetchPaymentFormParams;
        zuoraScript.src = ZUORA_SCRIPT_URL;
        document.head.appendChild(zuoraScript);
      } else {
        this.fetchPaymentFormParams();
      }
    },
    handleZuoraCallback(response) {
      this.paymentFormSubmitted(response);
      if (response?.success === 'true') {
        this.$emit('success');
      } else {
        this.$emit('error', response?.errorMessage);
        this.track('error', {
          label: 'payment_form_submitted',
          property: response?.errorMessage,
        });
      }
    },
    renderZuoraIframe() {
      const params = { ...this.paymentFormParams, ...ZUORA_IFRAME_OVERRIDE_PARAMS };
      window.Z.runAfterRender(() => {
        this.zuoraIframeRendered();
        this.track('iframe_loaded');
      });
      window.Z.render(params, {}, this.handleZuoraCallback);
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoadingPaymentMethod" size="lg" />
    <div v-show="active && !isLoadingPaymentMethod" id="zuora_payment"></div>
  </div>
</template>
