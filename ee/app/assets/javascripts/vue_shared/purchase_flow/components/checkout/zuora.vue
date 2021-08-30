<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { pick } from 'lodash';
import Api from 'ee/api';
import {
  ERROR_LOADING_PAYMENT_FORM,
  ZUORA_SCRIPT_URL,
  ZUORA_IFRAME_OVERRIDE_PARAMS,
  PAYMENT_FORM_ID,
} from 'ee/subscriptions/constants';
import updateStateMutation from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import activateNextStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/activate_next_step.mutation.graphql';
import createFlash from '~/flash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      paymentFormParams: null,
      zuoraLoaded: false,
      zuoraScriptEl: null,
    };
  },
  computed: {
    shouldShowZuoraFrame() {
      return this.active && this.zuoraLoaded && !this.isLoading;
    },
  },
  mounted() {
    this.loadZuoraScript();
  },
  methods: {
    zuoraIframeRendered() {
      this.isLoading = false;
      this.zuoraLoaded = true;
    },
    fetchPaymentFormParams() {
      this.isLoading = true;

      return Api.fetchPaymentFormParams(PAYMENT_FORM_ID)
        .then(({ data }) => {
          this.paymentFormParams = data;
          this.renderZuoraIframe();
        })
        .catch(() => {
          createFlash({ message: ERROR_LOADING_PAYMENT_FORM });
        });
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
    paymentFormSubmitted({ refId }) {
      this.isLoading = true;

      return Api.fetchPaymentMethodDetails(refId)
        .then(({ data }) => {
          return pick(
            data,
            'id',
            'credit_card_expiration_month',
            'credit_card_expiration_year',
            'credit_card_type',
            'credit_card_mask_number',
          );
        })
        .then((paymentMethod) => convertObjectPropsToCamelCase(paymentMethod))
        .then((paymentMethod) => this.updateState({ paymentMethod }))
        .then(() => this.activateNextStep())
        .catch((error) =>
          createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true }),
        )
        .finally(() => {
          this.isLoading = false;
        });
    },
    renderZuoraIframe() {
      const params = { ...this.paymentFormParams, ...ZUORA_IFRAME_OVERRIDE_PARAMS };
      window.Z.runAfterRender(this.zuoraIframeRendered);
      window.Z.render(params, {}, this.paymentFormSubmitted);
    },
    activateNextStep() {
      return this.$apollo
        .mutate({
          mutation: activateNextStepMutation,
        })
        .catch((error) => {
          createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
        });
    },
    updateState(payload) {
      return this.$apollo
        .mutate({
          mutation: updateStateMutation,
          variables: {
            input: payload,
          },
        })
        .catch((error) => {
          createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" />
    <div v-show="shouldShowZuoraFrame" id="zuora_payment"></div>
  </div>
</template>
