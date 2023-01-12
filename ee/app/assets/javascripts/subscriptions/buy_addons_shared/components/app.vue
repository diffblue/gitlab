<script>
import emptySvg from '@gitlab/svgs/dist/illustrations/security-dashboard-empty-state.svg';
import { GlEmptyState, GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import OrderSummary from 'jh_else_ee/subscriptions/buy_addons_shared/components/order_summary.vue';
import { ERROR_FETCHING_DATA_HEADER, ERROR_FETCHING_DATA_DESCRIPTION } from '~/ensure_data';
import Checkout from 'jh_else_ee/subscriptions/buy_addons_shared/components/checkout.vue';
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
    StepOrderApp,
  },
  inject: ['tags', 'i18n'],
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
      const formulaText = this.isQuantityValid ? this.i18n.formula : this.i18n.formulaWithAlert;
      return sprintf(formulaText, {
        quantity: formatNumber(this.plan.quantityPerPack),
        units: this.plan.productUnit,
      });
    },
    formulaTotal() {
      const total = sprintf(this.i18n.formulaTotal, {
        quantity: formatNumber(this.totalUnits),
      });
      return this.isQuantityValid ? total : '';
    },
    plan() {
      const [plan] = this.plans;
      return plan;
    },
    totalUnits() {
      return this.quantity * this.plan.quantityPerPack;
    },
    summaryTitle() {
      return sprintf(this.i18n.summaryTitle(this.quantity), { quantity: this.quantity });
    },
    summaryTotal() {
      return sprintf(this.i18n.summaryTotal, {
        quantity: formatNumber(this.totalUnits),
      });
    },
  },
  methods: {
    pricePerUnitLabel(price) {
      return sprintf(this.i18n.pricePerUnit, {
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
  <step-order-app v-else-if="!$apollo.loading" data-testid="buy-addons-shared">
    <template #checkout>
      <gl-alert
        v-if="alertMessage"
        class="checkout-alert gl-mb-5"
        variant="danger"
        :dismissible="false"
      >
        {{ alertMessage }}
      </gl-alert>
      <checkout :plan="plan" @alertError="alertError">
        <template #purchase-details>
          <addon-purchase-details
            :product-label="plan.label"
            :quantity="quantity"
            :show-alert="true"
            :alert-text="i18n.alertText"
            @alertError="alertError"
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
    </template>
    <template #order-summary>
      <order-summary
        :plan="plan"
        :title="i18n.title"
        :purchase-has-expiration="plan.hasExpiration"
        @alertError="alertError"
      >
        <template #price-per-unit="{ price }">
          {{ pricePerUnitLabel(price) }}
        </template>
      </order-summary>
    </template>
  </step-order-app>
</template>
