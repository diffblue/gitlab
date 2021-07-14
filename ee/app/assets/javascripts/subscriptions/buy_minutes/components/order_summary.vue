<script>
import { GlIcon, GlCollapse, GlCollapseToggleDirective } from '@gitlab/ui';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import { TAX_RATE } from 'ee/subscriptions/new/constants';
import formattingMixins from 'ee/subscriptions/new/formatting_mixins';
import { sprintf, s__ } from '~/locale';
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
  },
  apollo: {
    state: {
      query: stateQuery,
      manual: true,
      result({ data }) {
        this.namespaces = data.namespaces;
        this.subscription = data.subscription;
      },
    },
  },
  data() {
    return {
      subscription: {},
      namespaces: [],
      isBottomSummaryVisible: false,
    };
  },
  computed: {
    selectedPlanPrice() {
      return this.plan.pricePerYear;
    },
    selectedGroup() {
      return this.namespaces.find((group) => group.id === Number(this.subscription.namespaceId));
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
    namespaceName() {
      return this.selectedGroup.name;
    },
    titleWithName() {
      return sprintf(this.$options.i18n.title, { name: this.namespaceName });
    },
    isVisible() {
      return !this.$apollo.loading;
    },
  },
  i18n: {
    title: s__("Checkout|%{name}'s CI minutes"),
  },
  taxRate: TAX_RATE,
};
</script>
<template>
  <div
    v-if="isVisible"
    class="order-summary gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-mt-2 mt-lg-5"
  >
    <div class="d-lg-none">
      <div v-gl-collapse-toggle.summary-details>
        <h4 class="d-flex justify-content-between gl-font-lg">
          <div class="d-flex">
            <gl-icon v-if="isBottomSummaryVisible" name="chevron-down" />
            <gl-icon v-else name="chevron-right" />
            <div data-testid="title">{{ titleWithName }}</div>
          </div>
          <div class="gl-ml-3" data-testid="amount">
            {{ formatAmount(totalAmount, quantityPresent) }}
          </div>
        </h4>
      </div>
      <gl-collapse id="summary-details" v-model="isBottomSummaryVisible">
        <summary-details
          :vat="vat"
          :total-ex-vat="totalExVat"
          :quantity-present="quantityPresent"
          :selected-plan-text="plan.name"
          :selected-plan-price="selectedPlanPrice"
          :total-amount="totalAmount"
          :quantity="subscription.quantity"
          :tax-rate="$options.taxRate"
        />
      </gl-collapse>
    </div>
    <div class="d-none d-lg-block">
      <div class="append-bottom-20">
        <h4>
          {{ titleWithName }}
        </h4>
      </div>
      <summary-details
        :vat="vat"
        :total-ex-vat="totalExVat"
        :quantity-present="quantityPresent"
        :selected-plan-text="plan.name"
        :selected-plan-price="selectedPlanPrice"
        :total-amount="totalAmount"
        :quantity="subscription.quantity"
        :tax-rate="$options.taxRate"
      />
    </div>
  </div>
</template>
