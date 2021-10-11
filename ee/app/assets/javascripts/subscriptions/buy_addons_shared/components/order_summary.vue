<script>
import { GlIcon, GlCollapse, GlCollapseToggleDirective } from '@gitlab/ui';
import find from 'lodash/find';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import { TAX_RATE } from 'ee/subscriptions/new/constants';
import formattingMixins from 'ee/subscriptions/new/formatting_mixins';
import { sprintf } from '~/locale';
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
      },
    },
  },
  data() {
    return {
      isBottomSummaryVisible: false,
      selectedNamespace: {},
      subscription: {},
    };
  },
  computed: {
    selectedPlanPrice() {
      return this.plan.pricePerYear;
    },
    totalExVat() {
      return this.subscription.quantity * this.selectedPlanPrice;
    },
    vat() {
      return TAX_RATE * this.totalExVat;
    },
    totalAmount() {
      return this.totalExVat + this.vat;
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
    isVisible() {
      return !this.$apollo.loading;
    },
  },
  taxRate: TAX_RATE,
};
</script>
<template>
  <div
    v-if="isVisible"
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
            {{ formatAmount(totalAmount, quantityPresent) }}
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
          :purchase-has-expiration="purchaseHasExpiration"
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
        :purchase-has-expiration="purchaseHasExpiration"
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
