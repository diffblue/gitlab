<script>
import * as Sentry from '@sentry/browser';
import { GlCard, GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { unescape, isEmpty } from 'lodash';
import { sprintf, s__ } from '~/locale';
import { trackCheckout } from '~/google_tag_manager';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import Tracking from '~/tracking';

import SummaryDetails from 'jh_else_ee/subscriptions/new/components/order_summary/summary_details.vue';
import invoicePreviewQuery from 'ee/subscriptions/graphql/queries/new_subscription_invoice_preview.customer.query.graphql';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import {
  CHARGE_PROCESSING_TYPE,
  VALIDATION_ERROR_CODE,
  INVALID_PROMO_CODE_ERROR_MESSAGE,
  PROMO_CODE_USER_QUANTITY_ERROR_MESSAGE,
  PurchaseEvent,
} from 'ee/subscriptions/new/constants';
import { isInvalidPromoCodeError } from 'ee/subscriptions/new/utils';
import formattingMixins from '../formatting_mixins';
import PromoCodeInput from './promo_code_input.vue';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    PromoCodeInput,
    SummaryDetails,
    GlCard,
    GlLoadingIcon,
  },
  mixins: [formattingMixins, glFeatureFlagsMixin(), trackingMixin],
  apollo: {
    invoicePreview: {
      client: CUSTOMERSDOT_CLIENT,
      query: invoicePreviewQuery,
      variables() {
        return {
          planId: this.selectedPlan,
          quantity: this.numberOfUsers,
          ...(this.sendPromoCodeToPreviewInvoice && { promoCode: this.promoCode }),
        };
      },
      update(data) {
        if (this.sendPromoCodeToPreviewInvoice) {
          this.track('success_response', { label: 'apply_coupon_code_success_saas' });
        }

        return data?.invoicePreview;
      },
      error(error) {
        this.handleError(error);
      },
      watchLoading(isLoading) {
        this.updateInvoicePreviewLoading(isLoading);
      },
      skip() {
        return (
          !this.usersPresent ||
          !this.selectedPlan ||
          !this.glFeatures.useInvoicePreviewApiInSaasPurchase
        );
      },
    },
  },
  data() {
    return {
      invoicePreview: undefined,
      promoCodeErrorMessage: undefined,
      isPromoCodeValid: true,
    };
  },
  computed: {
    ...mapState(['numberOfUsers', 'selectedPlan', 'promoCode']),
    ...mapGetters([
      'selectedPlanPrice',
      'name',
      'usersPresent',
      'isGroupSelected',
      'isSelectedGroupPresent',
      'isEligibleToUsePromoCode',
      'showAmount',
      'totalAmount',
      'discountItem',
    ]),
    titleWithName() {
      return sprintf(this.$options.i18n.title, { name: this.name });
    },
    isLoading() {
      return this.$apollo.queries?.invoicePreview?.loading;
    },
    legacyInvoicePreview() {
      if (this.glFeatures.useInvoicePreviewApiInSaasPurchase || !this.isGroupSelected) {
        return null;
      }

      const amount = this.numberOfUsers * this.selectedPlanPrice;

      return {
        invoice: {
          amountWithoutTax: amount,
        },
        invoiceItem: [
          {
            chargeAmount: amount,
            processingType: CHARGE_PROCESSING_TYPE,
            unitPrice: this.selectedPlanPrice,
          },
        ],
      };
    },
    sendPromoCodeToPreviewInvoice() {
      return this.isEligibleToUsePromoCode && !isEmpty(this.promoCode) && this.isPromoCodeValid;
    },
    showPromoCode() {
      return this.isEligibleToUsePromoCode && this.glFeatures.useInvoicePreviewApiInSaasPurchase;
    },
    isApplyingPromoCode() {
      return this.sendPromoCodeToPreviewInvoice && this.isLoading && !this.hasDiscount;
    },
    hasDiscount() {
      return Boolean(this.discountItem);
    },
    showSuccessAlert() {
      return this.showAmount && this.hasDiscount;
    },
  },
  watch: {
    selectedPlan() {
      this.resetPromoCodeErrorMessage();
    },
    usersPresent(usersPresent) {
      // Clear promo code quantity error message when quantity is valid
      if (usersPresent && this.promoCodeErrorMessage === PROMO_CODE_USER_QUANTITY_ERROR_MESSAGE) {
        this.resetPromoCodeErrorMessage();
      }
    },
    legacyInvoicePreview: {
      handler(val) {
        // val is only truthy if FF is off and we're using legacy calculation
        if (!val) {
          return;
        }

        this.updateInvoicePreview(val);
      },
      immediate: true,
    },
    invoicePreview(val) {
      if (val) {
        this.clearError();
      }

      this.updateInvoicePreview(val);
    },
  },
  mounted() {
    trackCheckout(this.selectedPlan, this.numberOfUsers);
  },
  methods: {
    ...mapActions(['updateInvoicePreviewLoading', 'updateInvoicePreview', 'updatePromoCode']),
    clearError() {
      this.$emit(PurchaseEvent.ERROR_RESET);
    },
    handleError(error) {
      this.invoicePreview = null;

      const { gqlError, networkError } = error;
      const gqlErrorExtensions = gqlError?.extensions;

      let errorMessage = this.$options.i18n.errorMessageText;

      if (gqlErrorExtensions) {
        const { message } = gqlErrorExtensions || {};

        if (isInvalidPromoCodeError(gqlErrorExtensions)) {
          this.isPromoCodeValid = false;
          this.promoCodeErrorMessage = INVALID_PROMO_CODE_ERROR_MESSAGE;
          this.track('failure_response', { label: 'apply_coupon_code_failure_saas' });
          return;
        }
        if (gqlError.message) {
          errorMessage = gqlError.message;
        } else if (message) {
          errorMessage = message;
        }
      } else if (networkError) {
        const message = sprintf(s__('Checkout|Network Error: %{message}'), {
          message: networkError.message,
        });
        // Unescape network errors since it has escaped characters
        errorMessage = unescape(message);
      }

      if (gqlError?.extensions?.code !== VALIDATION_ERROR_CODE) {
        Sentry.captureException(error);
      }

      this.$emit(PurchaseEvent.ERROR, new Error(errorMessage));
    },
    resetPromoCodeErrorMessage() {
      this.promoCodeErrorMessage = undefined;
    },
    handlePromoCodeUpdate() {
      // reset promo code when updated until requested to apply to avoid
      // using previously entered values in preview/purchase API calls
      this.updatePromoCode('');
      this.resetPromoCodeErrorMessage();
    },
    applyPromoCode(promoCode) {
      if (this.usersPresent) {
        this.clearError();
        this.resetPromoCodeErrorMessage();
        this.isPromoCodeValid = true;
        this.updatePromoCode(promoCode);

        if (this.sendPromoCodeToPreviewInvoice) {
          this.track('click_button', { label: 'apply_coupon_code_saas' });
        }
      } else {
        this.promoCodeErrorMessage = PROMO_CODE_USER_QUANTITY_ERROR_MESSAGE;
      }
    },
  },
  i18n: {
    title: s__("Checkout|%{name}'s GitLab subscription"),
    errorMessageText: s__('Checkout|Something went wrong while loading price details.'),
  },
};
</script>
<template>
  <gl-card
    v-if="!isGroupSelected || isSelectedGroupPresent"
    class="order-summary gl-display-flex gl-flex-direction-column gl-flex-grow-1"
  >
    <div class="gl-lg-display-none">
      <h4
        class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-font-lg gl-my-0"
      >
        <div class="gl-display-flex gl-align-items-center">
          <span class="gl-ml-2">{{ titleWithName }}</span>
        </div>
        <gl-loading-icon v-if="isLoading" inline size="sm" class="gl-my-auto gl-ml-3" />
        <span v-else class="gl-ml-3">{{ formatAmount(totalAmount, showAmount) }}</span>
      </h4>
      <summary-details class="gl-mt-6">
        <template v-if="showPromoCode" #promo-code>
          <promo-code-input
            :show-success-alert="showSuccessAlert"
            :is-parent-form-loading="isLoading"
            :is-applying-promo-code="isApplyingPromoCode"
            :error-message="promoCodeErrorMessage"
            @promo-code-updated="handlePromoCodeUpdate"
            @apply-promo-code="applyPromoCode"
          />
        </template>
      </summary-details>
    </div>
    <div class="gl-display-none gl-lg-display-block" data-qa-selector="order_summary">
      <h4 class="gl-my-0 gl-font-lg" data-qa-selector="title">{{ titleWithName }}</h4>
      <summary-details class="gl-mt-6">
        <template v-if="showPromoCode" #promo-code>
          <promo-code-input
            :show-success-alert="showSuccessAlert"
            :is-parent-form-loading="isLoading"
            :is-applying-promo-code="isApplyingPromoCode"
            :error-message="promoCodeErrorMessage"
            @promo-code-updated="handlePromoCodeUpdate"
            @apply-promo-code="applyPromoCode"
          />
        </template>
      </summary-details>
    </div>
  </gl-card>
</template>
