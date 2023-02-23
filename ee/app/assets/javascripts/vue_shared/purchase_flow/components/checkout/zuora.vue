<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { pick } from 'lodash';
import Api from 'ee/api';
import {
  ERROR_LOADING_PAYMENT_FORM,
  PAYMENT_FORM_ID,
  ZUORA_IFRAME_OVERRIDE_PARAMS,
  ZUORA_SCRIPT_URL,
} from 'ee/subscriptions/constants';
import updateStateMutation from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import activateNextStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/activate_next_step.mutation.graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

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
    accountId: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isLoading: false,
      paymentFormParams: {},
      zuoraLoaded: false,
      zuoraScriptEl: null,
    };
  },
  computed: {
    shouldShowZuoraFrame() {
      return this.active && this.zuoraLoaded && !this.isLoading;
    },
    renderParams() {
      return {
        ...this.paymentFormParams,
        ...ZUORA_IFRAME_OVERRIDE_PARAMS,
        // @TODO: should the component handle re-rendering the form in case this changes?
        field_accountId: this.accountId,
      };
    },
  },
  mounted() {
    this.loadZuoraScript();
  },
  methods: {
    zuoraIframeRendered() {
      this.isLoading = false;
      this.zuoraLoaded = true;
      this.track('iframe_loaded');
    },
    fetchPaymentFormParams() {
      this.isLoading = true;

      return Api.fetchPaymentFormParams(PAYMENT_FORM_ID)
        .then(({ data }) => {
          this.paymentFormParams = data;
          this.renderZuoraIframe();
        })
        .catch((error) => {
          this.$emit(PurchaseEvent.ERROR, new Error(ERROR_LOADING_PAYMENT_FORM));
          this.track('error', {
            label: 'payment_form_fetch_params',
            property: error?.message,
          });
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
    paymentFormSubmitted({ refId } = {}) {
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
        .then(() => this.track('success'))
        .then(() => this.activateNextStep())
        .catch((error) => {
          this.$emit(PurchaseEvent.ERROR, error);
          this.track('error', {
            label: 'payment_form_submitted',
            property: error?.message,
          });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    renderZuoraIframe() {
      window.Z.runAfterRender(this.zuoraIframeRendered);
      window.Z.render(this.renderParams, {}, this.paymentFormSubmitted);
    },
    activateNextStep() {
      return this.$apollo.mutate({
        mutation: activateNextStepMutation,
      });
    },
    updateState(payload) {
      return this.$apollo.mutate({
        mutation: updateStateMutation,
        variables: {
          input: payload,
        },
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
