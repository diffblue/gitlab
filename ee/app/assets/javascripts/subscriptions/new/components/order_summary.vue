<script>
import { GlCard, GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import * as Sentry from '@sentry/browser';
import { unescape } from 'lodash';
import { sprintf, s__ } from '~/locale';
import { trackCheckout } from '~/google_tag_manager';
import SummaryDetails from 'jh_else_ee/subscriptions/new/components/order_summary/summary_details.vue';
import invoicePreviewQuery from 'ee/subscriptions/graphql/queries/new_subscription_invoice_preview.customer.query.graphql';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import { CHARGE_PROCESSING_TYPE, VALIDATION_ERROR_CODE } from 'ee/subscriptions/new/constants';
import formattingMixins from '../formatting_mixins';
import PromoCodeInput from './promo_code_input.vue';

export default {
  components: {
    PromoCodeInput,
    SummaryDetails,
    GlCard,
    GlLoadingIcon,
  },
  mixins: [formattingMixins],
  apollo: {
    invoicePreview: {
      client: CUSTOMERSDOT_CLIENT,
      query: invoicePreviewQuery,
      manual: true,
      variables() {
        return {
          planId: this.selectedPlan,
          quantity: this.numberOfUsers,
        };
      },
      result({ data }) {
        if (!data) {
          return;
        }

        const { invoice, invoiceItem } = data.invoicePreview;
        this.invoice = invoice;
        this.invoiceItem = invoiceItem;
        this.updateHasValidPriceDetails(true);
        this.clearError();
      },
      error(error) {
        this.handleError(error);
      },
      skip() {
        return !this.usersPresent || !this.selectedPlan;
      },
    },
  },
  data() {
    return {
      hasError: false,
      invoice: undefined,
      invoiceItem: undefined,
    };
  },
  computed: {
    ...mapState(['numberOfUsers', 'selectedPlan', 'taxRate']),
    ...mapGetters([
      'selectedPlanPrice',
      'selectedPlanText',
      'name',
      'usersPresent',
      'isGroupSelected',
      'isSelectedGroupPresent',
      'isEligibleToUsePromoCode',
    ]),
    titleWithName() {
      return sprintf(this.$options.i18n.title, { name: this.name });
    },
    chargeItem() {
      return this.invoiceItem?.find((item) => item.processingType === CHARGE_PROCESSING_TYPE);
    },
    totalExVat() {
      return this.hideAmount ? 0 : this.chargeItem?.chargeAmount ?? 0;
    },
    vat() {
      return this.taxRate * this.totalExVat;
    },
    totalAmount() {
      const amountWithoutTax = this.invoice?.amountWithoutTax ?? 0;
      return this.hideAmount ? 0 : amountWithoutTax + this.vat;
    },
    startDate() {
      return this.chargeItem?.serviceStartDate;
    },
    endDate() {
      return this.chargeItem?.serviceEndDate;
    },
    isLoading() {
      return this.$apollo.queries.invoicePreview.loading;
    },
    hideAmount() {
      return this.isLoading || this.hasError || !this.usersPresent;
    },
  },
  mounted() {
    trackCheckout(this.selectedPlan, this.numberOfUsers);
  },
  methods: {
    ...mapActions(['updateHasValidPriceDetails']),
    clearError() {
      this.hasError = false;
      this.$emit('error', null);
    },
    handleError(error) {
      this.hasError = true;
      this.invoice = undefined;
      this.invoiceItem = undefined;
      this.updateHasValidPriceDetails(false);

      const { gqlError, networkError } = error;

      let errorMessage = gqlError?.extensions?.message || this.$options.i18n.errorMessageText;

      if (networkError) {
        const message = sprintf(s__('Checkout|Network Error: %{message}'), {
          message: networkError.message,
        });
        errorMessage = unescape(message);
      }

      this.$emit('error', errorMessage);

      if (gqlError?.extensions?.code !== VALIDATION_ERROR_CODE) {
        Sentry.captureException(error);
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
        <span v-else class="gl-ml-3">{{ formatAmount(totalAmount, !hideAmount) }}</span>
      </h4>
      <summary-details
        class="gl-mt-6"
        :vat="vat"
        :total-ex-vat="totalExVat"
        :total-amount="totalAmount"
        :selected-plan-text="selectedPlanText"
        :selected-plan-price="selectedPlanPrice"
        :number-of-users="numberOfUsers"
        :users-present="usersPresent"
        :tax-rate="taxRate"
        :start-date="startDate"
        :end-date="endDate"
        :loading="isLoading"
        :has-error="hasError"
      >
        <template v-if="isEligibleToUsePromoCode" #promo-code>
          <promo-code-input />
        </template>
      </summary-details>
    </div>
    <div class="gl-display-none gl-lg-display-block" data-qa-selector="order_summary">
      <h4 class="gl-my-0 gl-font-lg" data-qa-selector="title">{{ titleWithName }}</h4>
      <summary-details
        class="gl-mt-6"
        :vat="vat"
        :total-ex-vat="totalExVat"
        :total-amount="totalAmount"
        :selected-plan-text="selectedPlanText"
        :selected-plan-price="selectedPlanPrice"
        :number-of-users="numberOfUsers"
        :users-present="usersPresent"
        :tax-rate="taxRate"
        :start-date="startDate"
        :end-date="endDate"
        :loading="isLoading"
        :has-error="hasError"
      >
        <template v-if="isEligibleToUsePromoCode" #promo-code>
          <promo-code-input />
        </template>
      </summary-details>
    </div>
  </gl-card>
</template>
