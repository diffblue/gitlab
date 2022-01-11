<script>
import { GlIcon, GlCollapse, GlCollapseToggleDirective } from '@gitlab/ui';
import find from 'lodash/find';
import { logError } from '~/lib/logger';

import { TAX_RATE } from 'ee/subscriptions/new/constants';
import { CUSTOMERSDOT_CLIENT, I18N_API_ERROR } from 'ee/subscriptions/buy_addons_shared/constants';
import formattingMixins from 'ee/subscriptions/new/formatting_mixins';
import { sprintf } from '~/locale';

import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import orderPreviewQuery from 'ee/subscriptions/graphql/queries/order_preview.customer.query.graphql';
import SummaryDetails from './order_summary/summary_details.vue';

export default {
  components: {
    SummaryDetails,
    GlIcon,
    GlCollapse,
  },
  directives: {
    GlCollapseToggle: GlCollapseToggleDirective,
  },
  mixins: [formattingMixins],
  props: {
    plan: {
      type: Object,
      required: true,
      validator(value) {
        return Object.prototype.hasOwnProperty.call(value, 'id');
      },
    },
    title: {
      type: String,
      required: true,
    },
    purchaseHasExpiration: {
      type: Boolean,
      required: false,
    },
  },
  apollo: {
    state: {
      query: stateQuery,
      manual: true,
      result({ data }) {
        const id = Number(data.selectedNamespaceId);
        this.selectedNamespace = find(data.eligibleNamespaces, { id });
        this.subscription = data.subscription;
        this.selectedNamespaceId = data.selectedNamespaceId;
      },
    },
    orderPreview: {
      client: CUSTOMERSDOT_CLIENT,
      query: orderPreviewQuery,
      variables() {
        return {
          namespaceId: this.selectedNamespaceId,
          newProductId: this.plan.id,
          newProductQuantity: this.subscription.quantity,
        };
      },
      manual: true,
      result({ data }) {
        if (data.errors) {
          this.hasError = true;
        } else if (data.orderPreview) {
          this.endDate = data.orderPreview.targetDate;
          this.proratedAmount = data.orderPreview.amount;
        }
      },
      error(error) {
        this.hasError = true;
        this.$emit('alertError', I18N_API_ERROR);
        logError(error);
      },
      skip() {
        return !this.purchaseHasExpiration;
      },
    },
  },
  data() {
    return {
      isBottomSummaryVisible: false,
      selectedNamespace: {},
      subscription: {},
      endDate: '',
      proratedAmount: 0,
      hasError: false,
    };
  },
  computed: {
    selectedPlanPrice() {
      return this.plan.pricePerYear;
    },
    totalExVat() {
      return this.hideAmount
        ? 0
        : this.proratedAmount || this.subscription.quantity * this.selectedPlanPrice;
    },
    vat() {
      return TAX_RATE * this.totalExVat;
    },
    totalAmount() {
      return this.hideAmount ? 0 : this.proratedAmount || this.totalExVat + this.vat;
    },
    quantityPresent() {
      return this.subscription.quantity > 0;
    },
    quantity() {
      return this.subscription.quantity || 0;
    },
    namespaceName() {
      return this.selectedNamespace.name;
    },
    titleWithName() {
      return sprintf(this.title, { name: this.namespaceName });
    },
    isLoading() {
      return this.$apollo.loading;
    },
    hideAmount() {
      return this.isLoading || this.hasError;
    },
  },
  taxRate: TAX_RATE,
};
</script>
<template>
  <div
    class="order-summary gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-mt-2 mt-lg-5"
  >
    <div class="gl-lg-display-none">
      <div v-gl-collapse-toggle.summary-details>
        <div class="gl-display-flex gl-justify-content-between gl-font-lg">
          <div class="gl-display-flex">
            <gl-icon v-if="isBottomSummaryVisible" name="chevron-down" />
            <gl-icon v-else name="chevron-right" />
            <h4 data-testid="title">{{ titleWithName }}</h4>
          </div>
          <p class="gl-ml-3" data-testid="amount">
            {{ totalAmount ? formatAmount(totalAmount, quantityPresent) : '-' }}
          </p>
        </div>
      </div>
      <gl-collapse id="summary-details" v-model="isBottomSummaryVisible">
        <summary-details
          :vat="vat"
          :total-ex-vat="totalExVat"
          :quantity-present="quantityPresent"
          :selected-plan-text="plan.name"
          :selected-plan-price="selectedPlanPrice"
          :total-amount="totalAmount"
          :quantity="quantity"
          :tax-rate="$options.taxRate"
          :subscription-end-date="endDate"
        >
          <template #price-per-unit="{ price }">
            <slot name="price-per-unit" :price="price"></slot>
          </template>
          <template #tooltip>
            <slot name="tooltip"></slot>
          </template>
        </summary-details>
      </gl-collapse>
    </div>
    <div class="gl-display-none gl-lg-display-block">
      <h4 class="gl-mb-5">
        {{ titleWithName }}
      </h4>
      <summary-details
        :vat="vat"
        :total-ex-vat="totalExVat"
        :quantity-present="quantityPresent"
        :selected-plan-text="plan.name"
        :selected-plan-price="selectedPlanPrice"
        :total-amount="totalAmount"
        :quantity="quantity"
        :tax-rate="$options.taxRate"
        :subscription-end-date="endDate"
      >
        <template #price-per-unit="{ price }">
          <slot name="price-per-unit" :price="price"></slot>
        </template>
        <template #tooltip>
          <slot name="tooltip"></slot>
        </template>
      </summary-details>
    </div>
  </div>
</template>
