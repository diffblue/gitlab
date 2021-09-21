<script>
import emptySvg from '@gitlab/svgs/dist/illustrations/security-dashboard-empty-state.svg';
import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import { ERROR_FETCHING_DATA_HEADER, ERROR_FETCHING_DATA_DESCRIPTION } from '~/ensure_data';
import { sprintf, formatNumber } from '~/locale';
import Checkout from '../../buy_addons_shared/components/checkout.vue';
import AddonPurchaseDetails from '../../buy_addons_shared/components/checkout/addon_purchase_details.vue';
import OrderSummary from '../../buy_addons_shared/components/order_summary.vue';
import {
  I18N_STORAGE_PRODUCT_LABEL,
  I18N_STORAGE_PRODUCT_UNIT,
  I18N_DETAILS_FORMULA,
  I18N_STORAGE_FORMULA_TOTAL,
  i18nStorageSummaryTitle,
  I18N_STORAGE_SUMMARY_TOTAL,
  planTags,
  CUSTOMER_CLIENT,
  STORAGE_PER_PACK,
} from '../../buy_addons_shared/constants';
import plansQuery from '../../graphql/queries/plans.customer.query.graphql';

export default {
  name: 'BuyStorageApp',
  components: {
    Checkout,
    GlEmptyState,
    OrderSummary,
    StepOrderApp,
    AddonPurchaseDetails,
  },
  i18n: {
    ERROR_FETCHING_DATA_HEADER,
    ERROR_FETCHING_DATA_DESCRIPTION,
    productLabel: I18N_STORAGE_PRODUCT_LABEL,
    productUnit: I18N_STORAGE_PRODUCT_UNIT,
    formula: I18N_DETAILS_FORMULA,
    formulaTotal: I18N_STORAGE_FORMULA_TOTAL,
    summaryTitle: i18nStorageSummaryTitle,
    summaryTotal: I18N_STORAGE_SUMMARY_TOTAL,
  },
  emptySvg,
  STORAGE_PER_PACK,
  data() {
    return {
      hasError: false,
    };
  },
  computed: {
    formulaText() {
      return sprintf(this.$options.i18n.formula, {
        quantity: formatNumber(STORAGE_PER_PACK),
        units: this.$options.i18n.productUnit,
      });
    },
  },
  methods: {
    formulaTotal(quantity) {
      return sprintf(this.$options.i18n.formulaTotal, { quantity: formatNumber(quantity) });
    },
    summaryTitle(quantity) {
      return sprintf(this.$options.i18n.summaryTitle(quantity), { quantity });
    },
    summaryTotal(quantity) {
      return sprintf(this.$options.i18n.summaryTotal, {
        quantity: formatNumber(quantity * STORAGE_PER_PACK),
      });
    },
  },
  apollo: {
    plans: {
      client: CUSTOMER_CLIENT,
      query: plansQuery,
      variables: {
        tags: [planTags.STORAGE_PLAN],
      },
      update(data) {
        if (!data?.plans?.length) {
          this.hasError = true;
          return null;
        }

        return data.plans;
      },
      error(error) {
        this.hasError = true;
        Sentry.captureException(error);
      },
    },
  },
};
</script>
<template>
  <gl-empty-state
    v-if="hasError"
    :title="$options.i18n.ERROR_FETCHING_DATA_HEADER"
    :description="$options.i18n.ERROR_FETCHING_DATA_DESCRIPTION"
    :svg-path="`data:image/svg+xml;utf8,${encodeURIComponent($options.emptySvg)}`"
  />
  <step-order-app v-else-if="!$apollo.loading">
    <template #checkout>
      <checkout :plan="plans[0]">
        <template #purchase-details>
          <addon-purchase-details
            :product-label="$options.i18n.productLabel"
            :quantity-per-pack="$options.STORAGE_PER_PACK"
          >
            <template #formula="{ quantity }">
              {{ formulaText }}
              <strong>{{ formulaTotal(quantity) }}</strong>
            </template>
            <template #summary-label="{ quantity }">
              <strong data-testid="summary-label">
                {{ summaryTitle(quantity) }}
              </strong>
              <p class="gl-mb-0">{{ summaryTotal(quantity) }}</p>
            </template>
          </addon-purchase-details>
        </template>
      </checkout>
    </template>
    <template #order-summary>
      <order-summary :plan="plans[0]" />
    </template>
  </step-order-app>
</template>
