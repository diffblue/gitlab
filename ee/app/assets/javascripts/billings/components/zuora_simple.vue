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

export const DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT = '200px';
export const ZUORA_EVENT_CATEGORY = 'Zuora_cc';
export const INVALID_SECURITY = 'Invalid_Security';

export const Action = Object.freeze({
  RESIZE: 'resize',
});

export const Event = Object.freeze({
  LOADED: 'loaded',
  LOAD_ERROR: 'load-error',
  LOADING: 'loading',
  PAYMENT_SUBMISSION_PROCESSING: 'payment-submission-processing',
  CLIENT_VALIDATION_ERROR: 'client-validation-error',
  SERVER_VALIDATION_ERROR: 'server-validation-error',
  PAYMENT_SUBMIT_ERROR: 'payment-submit-error',
  PAYMENT_SUBMIT_SUCCESS: 'payment-submit-success',
  SUCCESS: 'success',
});

export const TrackingEvent = Object.freeze({
  ERROR: 'error',
  ERROR_CLIENT: 'client_error',
  SUCCESS: 'success',
  IFRAME_LOADED: 'iframe_loaded',
});

export const TrackingLabel = Object.freeze({
  FETCH_PARAMS: 'payment_form_fetch_params',
  PAYMENT_SUBMITTED: 'payment_form_submitted',
  PAYMENT_VALIDATE: 'payment_method_validate',
  IFRAME_LOAD_ERROR: 'iframe_load_error',
  ZUORA_SCRIPT_LOAD_ERROR: 'zuora_script_load_error',
});

/*
[ZuoraSimple]  It renders an iframe with the relevant Zuora HPM.

This component will not re-render on failure, but instead displays
error states in either the iframe (client side validation) or as an alert.

[Events emitted]:
| Event Name                        | Payload                            | Event Trigger                                |
|-----------------------------------|------------------------------------|----------------------------------------------|
| loaded                            | N/A                                | iframe loads successfully                    |
| load-error                        | { errorCode, errorMessage }        | iframe load fails                            |
| loading                           | true/false                         | isLoading is updated                         |
| payment-submission-processing     | N/A                                | User clicks on make payment button           |
| client-validation-error           | { key, code, message }             | Client side validation from Zuora            |
| server-validation-error           | { key, code, message }             | Server side validation from Zuora            |
| payment-submit-error              | { errorCode, errorMessage }        | Error while making payment (post validation) |
| payment-submit-success            | { refId }                          | Success in creating payment method in Zuora  |
| success                           | N/A                                | Payment method validation success            |

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
      iframeLoadError: null,
      iframeHeight: this.initialHeight,
      isLoading: true,
      paymentFormParams: {},
      zuoraLoaded: false,
      zuoraScriptEl: null,
    };
  },
  computed: {
    style() {
      const height = Math.max(0, this.iframeHeight);
      return { height: `${height}px`, minHeight: DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT };
    },
    iFrameStyle() {
      if (this.isLoading) {
        return { height: 0 };
      }
      if (!this.zuoraLoaded) {
        return { height: DEFAULT_IFRAME_CONTAINER_MIN_HEIGHT };
      }
      return this.style;
    },
    renderParams() {
      return this.paymentFormParams;
    },
    shouldShowZuoraFrame() {
      return this.zuoraLoaded && !this.isLoading;
    },
  },
  watch: {
    isLoading(value) {
      this.$emit(Event.LOADING, value);
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
          this.track(TrackingEvent.ERROR, {
            label: TrackingLabel.FETCH_PARAMS,
            property: error.errorMessage || error.message || ERROR_LOADING_PAYMENT_FORM,
          });
        });
    },
    handleError(msg) {
      this.isLoading = false;
      this.error = msg;
    },
    /*
      For error handling, refer to below Zuora documentation:
      https://knowledgecenter.zuora.com/Billing/Billing_and_Payments/LA_Hosted_Payment_Pages/B_Payment_Pages_2.0/N_Error_Handling_for_Payment_Pages_2.0/Customize_Error_Messages_for_Payment_Pages_2.0#Define_Custom_Error_Message_Handling_Function
      https://knowledgecenter.zuora.com/Billing/Billing_and_Payments/LA_Hosted_Payment_Pages/B_Payment_Pages_2.0/H_Integrate_Payment_Pages_2.0/A_Advanced_Integration_of_Payment_Pages_2.0#Customize_Error_Messages_in_Advanced_Integration
    */
    handleErrorMessage(key, code, message) {
      const emitPayload = { key, code, message };
      if (key.toLowerCase() === 'error') {
        this.track(TrackingEvent.ERROR, {
          label: TrackingLabel.PAYMENT_SUBMITTED,
          property: message,
        });
        this.handleError(message);
        this.$emit(Event.SERVER_VALIDATION_ERROR, emitPayload);
      } else {
        window.Z.sendErrorMessageToHpm(key, message);
        this.isLoading = false;
        this.track(TrackingEvent.ERROR_CLIENT, {
          label: TrackingLabel.PAYMENT_SUBMITTED,
          property: message,
        });
        this.$emit(Event.CLIENT_VALIDATION_ERROR, emitPayload);
      }
    },
    handleMessage({ data } = {}) {
      const iFrameData = parseJson(data);
      const { action, height } = iFrameData;
      switch (action) {
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
      if (!this.iframeLoadError) {
        this.track(TrackingEvent.IFRAME_LOADED);
        this.$emit(Event.LOADED);
      }
    },
    loadZuoraScript() {
      this.isLoading = true;
      if (!this.zuoraScriptEl) {
        this.zuoraScriptEl = document.createElement('script');
        this.zuoraScriptEl.type = 'text/javascript';
        this.zuoraScriptEl.async = true;
        this.zuoraScriptEl.onload = this.fetchPaymentFormParams;
        this.zuoraScriptEl.onerror = this.handleZuoraScriptLoadError;
        this.zuoraScriptEl.src = ZUORA_SCRIPT_URL;
        document.head.appendChild(this.zuoraScriptEl);
      }
    },
    handleZuoraScriptLoadError() {
      this.handleError(ERROR_LOADING_PAYMENT_FORM);
      this.$emit(Event.LOAD_ERROR);
      this.track(TrackingEvent.ERROR, {
        label: TrackingLabel.ZUORA_SCRIPT_LOAD_ERROR,
        property: ERROR_LOADING_PAYMENT_FORM,
      });
    },
    paymentFormSubmitted({ success, refId, errorCode, errorMessage } = {}) {
      if (parseBoolean(success)) {
        this.$emit(Event.PAYMENT_SUBMIT_SUCCESS, { refId });
        return this.validatePaymentMethod(refId);
      }

      this.handleError(errorMessage);
      let event;
      let trackingLabel;
      if (errorCode === INVALID_SECURITY) {
        event = Event.LOAD_ERROR;
        trackingLabel = TrackingLabel.IFRAME_LOAD_ERROR;
        this.iframeLoadError = true;
        this.error = ERROR_LOADING_PAYMENT_FORM;
      } else {
        event = Event.PAYMENT_SUBMIT_ERROR;
        trackingLabel = TrackingLabel.PAYMENT_SUBMITTED;
      }
      this.$emit(event, { errorCode, errorMessage });
      return this.track(TrackingEvent.ERROR, {
        label: trackingLabel,
        property: errorMessage,
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
      this.$emit(Event.PAYMENT_SUBMISSION_PROCESSING);
    },
    validatePaymentMethod(id) {
      this.isLoading = true;
      return Api.validatePaymentMethod(id, this.currentUserId)
        .then(({ data }) => {
          if (!parseBoolean(data.success)) {
            throw new Error();
          }
          this.isLoading = false;
          this.$emit(Event.SUCCESS);
          this.track(TrackingEvent.SUCCESS, {
            label: TrackingLabel.PAYMENT_VALIDATE,
            property: `payment_method_id: ${id}`,
          });
        })
        .catch(({ message }) => {
          const errorMessage = message || this.$options.i18n.paymentValidationError;
          this.handleError(errorMessage);
          this.track(TrackingEvent.ERROR, {
            label: TrackingLabel.PAYMENT_VALIDATE,
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
    <div v-if="isLoading" :style="style" data-testid="loading-container">
      <gl-loading-icon size="lg" class="gl-relative gl-top-half gl-w-full" />
    </div>
    <div
      id="zuora_payment"
      :style="iFrameStyle"
      :class="{ 'gl-visibility-hidden': !shouldShowZuoraFrame }"
    ></div>
  </div>
</template>

<style>
#z_hppm_iframe {
  width: 100% !important;
}
</style>
