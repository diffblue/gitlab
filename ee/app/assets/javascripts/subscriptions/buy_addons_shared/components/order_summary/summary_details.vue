<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import formattingMixins from 'ee/subscriptions/new/formatting_mixins';
import { s__ } from '~/locale';

export default {
  components: {
    GlLink,
    GlSprintf,
  },
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
    hasPositiveQuantity() {
      return this.quantity > 0;
    },
    taxAmount() {
      return this.taxRate ? this.formatAmount(this.vat, this.quantity > 0) : '–';
    },
    taxLine() {
      return `${this.$options.i18n.tax} ${this.$options.i18n.taxNote}`;
    },
  },
  i18n: {
    quantity: s__('Checkout|(x%{quantity})'),
    pricePerUnitPerYear: s__('Checkout|$%{selectedPlanPrice} per pack of 1,000 minutes'),
    dates: s__('Checkout|%{startDate} - %{endDate}'),
    subtotal: s__('Checkout|Subtotal'),
    tax: s__('Checkout|Tax'),
    taxNote: s__('Checkout|(may be %{linkStart}charged upon purchase%{linkEnd})'),
    total: s__('Checkout|Total'),
  },
};
</script>
<template>
  <div>
    <div
      class="gl-display-flex gl-justify-content-space-between gl-font-weight-bold gl-mt-3 gl-mb-3"
    >
      <div data-testid="selected-plan">
        {{ selectedPlanText }}
        <span v-if="quantity" data-testid="quantity">{{
          sprintf($options.i18n.quantity, { quantity })
        }}</span>
      </div>
      <div data-testid="amount">{{ formatAmount(totalExVat, hasPositiveQuantity) }}</div>
    </div>
    <div class="gl-text-gray-500" data-testid="price-per-unit">
      {{
        sprintf($options.i18n.pricePerUnitPerYear, {
          selectedPlanPrice: selectedPlanPrice.toLocaleString(),
        })
      }}
    </div>
    <div v-if="purchaseHasExpiration" class="gl-text-gray-500" data-testid="subscription-period">
      {{
        sprintf($options.i18n.dates, {
          startDate: formatDate(startDate),
          endDate: formatDate(endDate),
        })
      }}
    </div>
    <div>
      <div class="border-bottom gl-mt-3 gl-mb-3"></div>
      <div class="gl-display-flex gl-justify-content-space-between gl-text-gray-500">
        <div>{{ $options.i18n.subtotal }}</div>
        <div data-testid="total-ex-vat">{{ formatAmount(totalExVat, hasPositiveQuantity) }}</div>
      </div>
      <div class="gl-display-flex gl-justify-content-space-between gl-text-gray-500">
        <div>
          <div data-testid="vat-info-line">
            <gl-sprintf :message="taxLine">
              <template #link="{ content }">
                <gl-link
                  class="gl-text-decoration-underline gl-text-gray-500"
                  href="https://about.gitlab.com/handbook/tax/#indirect-taxes-management"
                  target="_blank"
                  data-testid="vat-help-link"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </div>
        </div>
        <div data-testid="vat">{{ taxAmount }}</div>
      </div>
    </div>
    <div class="gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-mt-3 gl-mb-3"></div>
    <div class="gl-display-flex gl-justify-content-space-between gl-font-weight-bold gl-font-lg">
      <div>{{ $options.i18n.total }}</div>
      <div data-testid="total-amount">{{ formatAmount(totalAmount, hasPositiveQuantity) }}</div>
    </div>
  </div>
</template>
