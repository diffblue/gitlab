<script>
import { GlCard, GlCollapse, GlCollapseToggleDirective, GlIcon } from '@gitlab/ui';
import find from 'lodash/find';
import { PurchaseEvent, TAX_RATE } from 'ee/subscriptions/new/constants';
import { CUSTOMERSDOT_CLIENT } from 'ee/subscriptions/buy_addons_shared/constants';
import formattingMixins from 'ee/subscriptions/new/formatting_mixins';
import { sprintf } from '~/locale';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import orderPreviewQuery from 'ee/subscriptions/graphql/queries/order_preview.customer.query.graphql';
import SummaryDetails from 'jh_else_ee/subscriptions/buy_addons_shared/components/order_summary/summary_details.vue';

export default {
  components: {
    SummaryDetails,
    GlCard,
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
        if (!data) {
          return;
        }
        if (data.errors) {
          this.hasError = true;
        } else if (data.orderPreview) {
          this.endDate = data.orderPreview.targetDate;
          this.proratedAmount = data.orderPreview.amount;
        }
      },
      error(error) {
        this.hasError = true;
        this.$emit(PurchaseEvent.ERROR, error);
      },
      skip() {
        return !this.purchaseHasExpiration || !this.quantity;
      },
    },
  },
  data() {
    return {
      summaryDetailsAreVisible: false,
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
  <gl-card class="order-summary gl-display-flex gl-flex-direction-column gl-flex-grow-1">
    <div class="gl-lg-display-none">
      <h4
        v-gl-collapse-toggle.summary-details
        class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-font-lg gl-my-0"
      >
        <div class="gl-display-flex gl-align-items-center">
          <gl-icon v-if="summaryDetailsAreVisible" name="chevron-down" class="gl-flex-shrink-0" />
          <gl-icon v-else name="chevron-right" class="gl-flex-shrink-0" />
          <span class="gl-ml-2" data-testid="title">{{ titleWithName }}</span>
        </div>
        <span class="gl-ml-3" data-testid="amount">
          {{ totalAmount ? formatAmount(totalAmount, quantityPresent) : '-' }}
        </span>
      </h4>
      <gl-collapse id="summary-details" v-model="summaryDetailsAreVisible">
        <summary-details
          class="gl-mt-6"
          :vat="vat"
          :total-ex-vat="totalExVat"
          :quantity-present="quantityPresent"
          :selected-plan-text="plan.name"
          :selected-plan-price="selectedPlanPrice"
          :total-amount="totalAmount"
          :quantity="quantity"
          :tax-rate="$options.taxRate"
          :subscription-end-date="endDate"
          :has-expiration="purchaseHasExpiration"
        >
          <template #price-per-unit="{ price }">
            <slot name="price-per-unit" :price="price"></slot>
          </template>
        </summary-details>
      </gl-collapse>
    </div>
    <div class="gl-display-none gl-lg-display-block">
      <h4 class="gl-my-0 gl-font-lg">
        {{ titleWithName }}
      </h4>
      <summary-details
        class="gl-mt-6"
        :vat="vat"
        :total-ex-vat="totalExVat"
        :quantity-present="quantityPresent"
        :selected-plan-text="plan.name"
        :selected-plan-price="selectedPlanPrice"
        :total-amount="totalAmount"
        :quantity="quantity"
        :tax-rate="$options.taxRate"
        :subscription-end-date="endDate"
        :has-expiration="purchaseHasExpiration"
      >
        <template #price-per-unit="{ price }">
          <slot name="price-per-unit" :price="price"></slot>
        </template>
      </summary-details>
    </div>
  </gl-card>
</template>
