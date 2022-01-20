<script>
import emptySvg from '@gitlab/svgs/dist/illustrations/security-dashboard-empty-state.svg';
import { GlEmptyState, GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import OrderSummary from 'ee/subscriptions/buy_addons_shared/components/order_summary.vue';
import { ERROR_FETCHING_DATA_HEADER, ERROR_FETCHING_DATA_DESCRIPTION } from '~/ensure_data';
import Checkout from 'ee/subscriptions/buy_addons_shared/components/checkout.vue';
import AddonPurchaseDetails from 'ee/subscriptions/buy_addons_shared/components/checkout/addon_purchase_details.vue';
import { formatNumber, sprintf } from '~/locale';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';

import plansQuery from 'ee/subscriptions/graphql/queries/plans.customer.query.graphql';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';

export default {
  components: {
    AddonPurchaseDetails,
    Checkout,
    GlEmptyState,
    GlAlert,
    OrderSummary,
  },
  props: {
    config: {
      required: true,
      type: Object,
    },
    tags: {
      required: true,
      type: Array,
    },
  },
  data() {
    return {
      hasError: false,
      alertMessage: '',
    };
  },
  computed: {
    emptySvgPath() {
      return `data:image/svg+xml;utf8,${encodeURIComponent(emptySvg)}`;
    },
    errorDescription() {
      return ERROR_FETCHING_DATA_DESCRIPTION;
    },
    errorTitle() {
      return ERROR_FETCHING_DATA_HEADER;
    },
    isQuantityValid() {
      return Number.isFinite(this.quantity) && this.quantity > 0;
    },
    formulaText() {
      const formulaText = this.isQuantityValid ? this.config.formula : this.config.formulaWithAlert;
      return sprintf(formulaText, {
        quantity: formatNumber(this.config.quantityPerPack),
        units: this.config.productUnit,
      });
    },
    formulaTotal() {
      const total = sprintf(this.config.formulaTotal, {
        quantity: formatNumber(this.totalUnits),
      });
      return this.isQuantityValid ? total : '';
    },
    plan() {
      return {
        ...this.plans[0],
        isAddon: true,
      };
    },
    totalUnits() {
      return this.quantity * this.config.quantityPerPack;
    },
    summaryTitle() {
      return sprintf(this.config.summaryTitle(this.quantity), { quantity: this.quantity });
    },
    summaryTotal() {
      return sprintf(this.config.summaryTotal, {
        quantity: formatNumber(this.totalUnits),
      });
    },
  },
  methods: {
    pricePerUnitLabel(price) {
      return sprintf(this.config.pricePerUnit, {
        selectedPlanPrice: price,
      });
    },
    alertError(errorMessage) {
      this.alertMessage = errorMessage;
    },
  },
  apollo: {
    plans: {
      client: CUSTOMERSDOT_CLIENT,
      query: plansQuery,
      variables() {
        return { tags: this.tags };
      },
      update(data) {
        if (!data?.plans?.length) {
          this.hasError = true;
          return [];
        }
        return data.plans;
      },
      error(error) {
        this.hasError = true;
        Sentry.captureException(error);
      },
    },
    quantity: {
      query: stateQuery,
      update(data) {
        return data.subscription.quantity;
      },
    },
  },
};
</script>
<template>
  <gl-empty-state
    v-if="hasError"
    :description="errorDescription"
    :title="errorTitle"
    :svg-path="emptySvgPath"
  />
  <div
    v-else-if="!$apollo.loading"
    data-testid="buy-addons-shared"
    class="row gl-flex-grow-1 gl-flex-direction-column gl-flex-nowrap gl-lg-flex-direction-row gl-xl-flex-direction-row gl-lg-flex-wrap gl-xl-flex-wrap"
  >
    <div
      class="checkout-pane gl-px-3 gl-pt-5 gl-align-items-center gl-bg-gray-10 col-lg-7 gl-display-flex gl-flex-direction-column gl-flex-grow-1"
    >
      <gl-alert v-if="alertMessage" class="checkout-alert" variant="danger" :dismissible="false">
        {{ alertMessage }}
      </gl-alert>
      <checkout :plan="plan">
        <template #purchase-details>
          <addon-purchase-details
            :product-label="config.productLabel"
            :quantity="quantity"
            :show-alert="true"
            :alert-text="config.alertText"
          >
            <template #formula>
              {{ formulaText }}
              <strong>{{ formulaTotal }}</strong>
            </template>

            <template #summary-label>
              <strong data-testid="summary-label">
                {{ summaryTitle }}
              </strong>
              <div data-testid="summary-total">{{ summaryTotal }}</div>
            </template>
          </addon-purchase-details>
        </template>
      </checkout>
    </div>
    <div
      class="gl-pb-3 gl-px-3 gl-lg-px-7 col-lg-5 gl-display-flex gl-flex-direction-row gl-justify-content-center"
    >
      <order-summary
        :plan="plan"
        :title="config.title"
        :purchase-has-expiration="config.hasExpiration"
        @alertError="alertError"
      >
        <template #price-per-unit="{ price }">
          {{ pricePerUnitLabel(price) }}
        </template>
      </order-summary>
    </div>
  </div>
</template>
