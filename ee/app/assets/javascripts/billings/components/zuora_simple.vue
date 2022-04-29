<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import Api from 'ee/api';
import { ERROR_LOADING_PAYMENT_FORM, ZUORA_SCRIPT_URL } from 'ee/subscriptions/constants';
import { parseBoolean } from '~/lib/utils/common_utils';

const parseJson = (data) => {
  if (typeof data === 'string') {
    try {
      return JSON.parse(data);
    } catch (e) {
      return {};
    }
  }
  return {};
};

export const DEFAULT_IFRAME_BOTTOM_HEIGHT = 55;
export const DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT = '200px';
export const ERROR = 'error';
export const ERROR_CLIENT = 'client_error';
export const SUCCESS = 'success';
export const ZUORA_EVENT_CATEGORY = 'Zuora_cc';

export const Action = Object.freeze({
  CUSTOMIZE_ERROR_MESSAGE: 'customizeErrorMessage',
  RESIZE: 'resize',
});

export const Event = Object.freeze({
  FETCH_PARAMS: 'payment_form_fetch_params',
  IFRAME_LOADED: 'iframe_loaded',
  PAYMENT_SUBMITTED: 'payment_form_submitted',
  PAYMENT_VALIDATE: 'payment_method_validate',
});

/*
[ZuoraSimple]  It renders an iframe with the relevant Zuora HPM.

This component will not re-render on failure, but instead displays
error states in either the iframe (client side validation) or as an alert.
 */
export default {
  i18n: {
    paymentValidationError: s__('Billings|Error validating card details'),
  },
  name: 'ZuoraSimple',
  components: {
    GlAlert,
    GlLoadingIcon,
  },
  mixins: [Tracking.mixin({ category: ZUORA_EVENT_CATEGORY })],
  props: {
    currentUserId: {
      type: Number,
      required: true,
    },
    initialHeight: {
      type: Number,
      required: true,
    },
    paymentFormId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      error: null,
      iframeHeight: this.initialHeight,
      isLoading: true,
      paymentFormParams: {},
      zuoraLoaded: false,
      zuoraScriptEl: null,
    };
  },
  computed: {
    iframeCalculatedHeight() {
      return this.iframeHeight - DEFAULT_IFRAME_BOTTOM_HEIGHT;
    },
    iFrameStyle() {
      if (!this.zuoraLoaded) {
        return { height: DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT };
      }
      const height = Math.max(0, this.iframeCalculatedHeight);
      return { height: `${height}px`, minHeight: DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT };
    },
    renderParams() {
      return this.paymentFormParams;
    },
    shouldShowZuoraFrame() {
      return this.zuoraLoaded && !this.isLoading;
    },
  },
  mounted() {
    this.loadZuoraScript();
    window.addEventListener('message', this.handleMessage, true);
  },
  destroyed() {
    window.removeEventListener('message', this.handleMessage, true);
  },
  methods: {
    fetchPaymentFormParams() {
      this.isLoading = true;
      return Api.fetchPaymentFormParams(this.paymentFormId)
        .then(({ data }) => {
          if (data.errors || isEmpty(data)) {
            throw new Error(data.errors);
          }
          this.paymentFormParams = {
            ...data,
            location: btoa(window.location.href),
            user_id: this.currentUserId,
            // It won't use the Zuora callback upon success
            submitEnabled: 'true',
          };
          this.renderZuoraIframe();
        })
        .catch((error = {}) => {
          this.handleError(ERROR_LOADING_PAYMENT_FORM);
          this.track(ERROR, {
            label: Event.FETCH_PARAMS,
            property: error.errorMessage || error.message || ERROR_LOADING_PAYMENT_FORM,
          });
        });
    },
    handleError(msg) {
      this.isLoading = false;
      this.error = msg;
    },
    handleErrorMessage(key, code, msg) {
      if (key.toLowerCase() === ERROR) {
        this.track(ERROR, {
          label: Event.PAYMENT_SUBMITTED,
          property: msg,
        });
        this.handleError(msg);
      }
    },
    handleMessage({ data } = {}) {
      const iFrameData = parseJson(data);
      const { action, key, height, message } = iFrameData;
      switch (action) {
        case Action.CUSTOMIZE_ERROR_MESSAGE:
          window.Z.sendErrorMessageToHpm(key, message);
          this.track(ERROR_CLIENT, {
            label: Event.PAYMENT_SUBMITTED,
            property: message,
          });
          this.isLoading = false;
          break;
        case Action.RESIZE:
          this.iframeHeight = height > 0 ? height : this.iframeHeight;
          this.isLoading = false;
          break;
        default:
          break;
      }
    },
    iFrameDidRender() {
      this.isLoading = false;
      this.zuoraLoaded = true;
      this.track(Event.IFRAME_LOADED);
    },
    loadZuoraScript() {
      this.isLoading = true;
      if (!this.zuoraScriptEl) {
        this.zuoraScriptEl = document.createElement('script');
        this.zuoraScriptEl.type = 'text/javascript';
        this.zuoraScriptEl.async = true;
        this.zuoraScriptEl.onload = this.fetchPaymentFormParams;
        this.zuoraScriptEl.src = ZUORA_SCRIPT_URL;
        document.head.appendChild(this.zuoraScriptEl);
      }
    },
    paymentFormSubmitted({ message, success, refId } = {}) {
      if (parseBoolean(success)) {
        return this.validatePaymentMethod(refId);
      }
      this.handleError(message);
      return this.track(ERROR, {
        label: Event.PAYMENT_SUBMITTED,
        property: message,
      });
    },
    renderZuoraIframe() {
      window.Z.runAfterRender(this.iFrameDidRender);
      window.Z.renderWithErrorHandler(
        this.renderParams,
        {},
        this.paymentFormSubmitted,
        this.handleErrorMessage,
      );
    },
    submit() {
      window.Z.submit();
      this.error = null;
      this.isLoading = true;
    },
    validatePaymentMethod(id) {
      this.isLoading = true;
      return Api.validatePaymentMethod(id, this.currentUserId)
        .then(({ data }) => {
          if (!parseBoolean(data.success)) {
            throw new Error();
          }
          this.$emit(SUCCESS);
          this.track(SUCCESS, {
            label: Event.PAYMENT_VALIDATE,
            property: `payment_method_id: ${id}`,
          });
        })
        .catch(({ message }) => {
          const errorMessage = message || this.$options.i18n.paymentValidationError;
          this.handleError(errorMessage);
          this.track(ERROR, {
            label: Event.PAYMENT_VALIDATE,
            property: errorMessage,
          });
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = null">
      {{ error }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-absolute gl-top-half gl-w-full" />
    <div
      id="zuora_payment"
      :style="iFrameStyle"
      class="gl-overflow-hidden"
      :class="{ 'gl-visibility-hidden': !shouldShowZuoraFrame }"
    ></div>
  </div>
</template>

<style>
#z_hppm_iframe {
  width: 100% !important;
}
</style>
