<script>
import formattingMixins from 'ee/subscriptions/new/formatting_mixins';
import { s__ } from '~/locale';

export default {
  mixins: [formattingMixins],
  props: {
    vat: {
      type: Number,
      required: true,
    },
    totalExVat: {
      type: Number,
      required: true,
    },
    selectedPlanText: {
      type: String,
      required: true,
    },
    selectedPlanPrice: {
      type: Number,
      required: true,
    },
    totalAmount: {
      type: Number,
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
    },
    taxRate: {
      type: Number,
      required: false,
      default: null,
    },
    purchaseHasExpiration: {
      type: Boolean,
      required: false,
    },
  },
  data() {
    return {
      startDate: new Date(),
    };
  },
  computed: {
    endDate() {
      return this.startDate.setFullYear(this.startDate.getFullYear() + 1);
    },
  },
  i18n: {
    selectedPlanText: s__('Checkout|%{selectedPlanText} plan'),
    quantity: s__('Checkout|(x%{quantity})'),
    pricePerUnitPerYear: s__('Checkout|$%{selectedPlanPrice} per pack per year'),
    dates: s__('Checkout|%{startDate} - %{endDate}'),
    subtotal: s__('Checkout|Subtotal'),
    tax: s__('Checkout|Tax'),
    total: s__('Checkout|Total'),
  },
};
</script>
<template>
  <div>
    <div class="d-flex justify-content-between bold gl-mt-3 gl-mb-3">
      <div class="js-selected-plan">
        {{ sprintf($options.i18n.selectedPlanText, { selectedPlanText }) }}
        <span v-if="quantity > 0" class="js-quantity">{{
          sprintf($options.i18n.quantity, { quantity })
        }}</span>
      </div>
      <div class="js-amount">{{ formatAmount(totalExVat, quantity > 0) }}</div>
    </div>
    <div class="text-secondary js-per-unit">
      {{
        sprintf($options.i18n.pricePerUnitPerYear, {
          selectedPlanPrice: selectedPlanPrice.toLocaleString(),
        })
      }}
    </div>
    <div v-if="purchaseHasExpiration" class="text-secondary js-dates">
      {{
        sprintf($options.i18n.dates, {
          startDate: formatDate(startDate),
          endDate: formatDate(endDate),
        })
      }}
    </div>
    <div v-if="taxRate">
      <div class="border-bottom gl-mt-3 gl-mb-3"></div>
      <div class="d-flex justify-content-between text-secondary">
        <div>{{ $options.i18n.subtotal }}</div>
        <div class="js-total-ex-vat">{{ formatAmount(totalExVat, quantity > 0) }}</div>
      </div>
      <div class="d-flex justify-content-between text-secondary">
        <div>{{ $options.i18n.tax }}</div>
        <div class="js-vat">{{ formatAmount(vat, quantity > 0) }}</div>
      </div>
    </div>
    <div class="border-bottom gl-mt-3 gl-mb-3"></div>
    <div class="d-flex justify-content-between bold gl-font-lg">
      <div>{{ $options.i18n.total }}</div>
      <div class="js-total-amount">{{ formatAmount(totalAmount, quantity > 0) }}</div>
    </div>
  </div>
</template>
