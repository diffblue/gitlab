<script>
import { GlCard, GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import { unescape } from 'lodash';
import { sprintf, s__ } from '~/locale';
import { trackCheckout } from '~/google_tag_manager';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SummaryDetails from 'jh_else_ee/subscriptions/new/components/order_summary/summary_details.vue';
import invoicePreviewQuery from 'ee/subscriptions/graphql/queries/new_subscription_invoice_preview.customer.query.graphql';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import { CHARGE_PROCESSING_TYPE, VALIDATION_ERROR_CODE } from 'ee/subscriptions/new/constants';
import { createAlert } from '~/flash';
import formattingMixins from '../formatting_mixins';
import PromoCodeInput from './promo_code_input.vue';

export default {
  components: {
    PromoCodeInput,
    SummaryDetails,
    GlCard,
    GlLoadingIcon,
  },
  mixins: [formattingMixins, glFeatureFlagsMixin()],
  apollo: {
    invoicePreview: {
      client: CUSTOMERSDOT_CLIENT,
      query: invoicePreviewQuery,
      variables() {
        return {
          planId: this.selectedPlan,
          quantity: this.numberOfUsers,
        };
      },
      update(data) {
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
    };
  },
  computed: {
    ...mapState(['numberOfUsers', 'selectedPlan']),
    ...mapGetters([
      'selectedPlanPrice',
      'name',
      'usersPresent',
      'isGroupSelected',
      'isSelectedGroupPresent',
      'isEligibleToUsePromoCode',
      'hideAmount',
      'totalAmount',
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
          },
        ],
      };
    },
  },
  watch: {
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
    ...mapActions(['updateInvoicePreviewLoading', 'updateInvoicePreview']),
    clearError() {
      this.alert?.dismiss();
    },
    handleError(error) {
      this.invoicePreview = null;

      const { gqlError, networkError } = error;

      let errorMessage = gqlError?.extensions?.message || this.$options.i18n.errorMessageText;

      if (networkError) {
        const message = sprintf(s__('Checkout|Network Error: %{message}'), {
          message: networkError.message,
        });
        // Unescape network errors since it has escaped characters
        errorMessage = unescape(message);
      }

      let captureError = true;

      if (gqlError?.extensions?.code === VALIDATION_ERROR_CODE) {
        captureError = false;
      }

      // `alert` is intentionally not in `data` to avoid making it unnecessarily reactive
      this.alert = createAlert({ message: errorMessage, error, captureError });
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
      <summary-details class="gl-mt-6">
        <template v-if="isEligibleToUsePromoCode" #promo-code>
          <promo-code-input />
        </template>
      </summary-details>
    </div>
    <div class="gl-display-none gl-lg-display-block" data-qa-selector="order_summary">
      <h4 class="gl-my-0 gl-font-lg" data-qa-selector="title">{{ titleWithName }}</h4>
      <summary-details class="gl-mt-6">
        <template v-if="isEligibleToUsePromoCode" #promo-code>
          <promo-code-input />
        </template>
      </summary-details>
    </div>
  </gl-card>
</template>
