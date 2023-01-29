<script>
import { GlLink, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import formattingMixins from '../../formatting_mixins';

export default {
  components: {
    GlLink,
    GlSprintf,
    GlLoadingIcon,
  },
  mixins: [formattingMixins, Tracking.mixin()],
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
    numberOfUsers: {
      type: Number,
      required: true,
    },
    usersPresent: {
      type: Boolean,
      required: true,
    },
    taxRate: {
      type: Number,
      required: false,
      default: null,
    },
    startDate: {
      type: String,
      required: false,
      default: '',
    },
    endDate: {
      type: String,
      required: false,
      default: '',
    },
    loading: {
      type: Boolean,
      required: true,
    },
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    taxAmount() {
      return this.taxRate ? this.formatAmount(this.vat, this.showPrices) : '–';
    },
    taxLine() {
      return `${this.$options.i18n.tax} ${this.$options.i18n.taxNote}`;
    },
    showPrices() {
      return this.usersPresent && !this.hasError;
    },
  },
  i18n: {
    selectedPlanText: s__('Checkout|%{selectedPlanText} plan'),
    numberOfUsers: s__('Checkout|(x%{numberOfUsers})'),
    pricePerUserPerYear: s__('Checkout|$%{selectedPlanPrice} per user per year'),
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
    <div class="gl-display-flex gl-justify-content-space-between gl-font-weight-bold gl-mb-3">
      <div data-testid="selected-plan" data-qa-selector="selected_plan">
        {{ sprintf($options.i18n.selectedPlanText, { selectedPlanText }) }}
        <span
          v-if="usersPresent"
          data-testid="number-of-users"
          data-qa-selector="number_of_users"
          >{{ sprintf($options.i18n.numberOfUsers, { numberOfUsers }) }}</span
        >
      </div>
      <gl-loading-icon v-if="loading" inline class="gl-my-auto gl-ml-3" />
      <div v-else class="gl-ml-3" data-testid="amount" data-qa-selector="total">
        {{ formatAmount(totalExVat, showPrices) }}
      </div>
    </div>
    <div v-if="!loading" class="gl-text-gray-500" data-testid="per-user">
      {{
        sprintf($options.i18n.pricePerUserPerYear, {
          selectedPlanPrice: selectedPlanPrice.toLocaleString(),
        })
      }}
    </div>
    <div v-if="!loading" class="gl-text-gray-500" data-testid="dates">
      {{
        sprintf($options.i18n.dates, {
          startDate: formatDate(startDate),
          endDate: formatDate(endDate),
        })
      }}
    </div>
    <slot name="promo-code"></slot>
    <div>
      <div class="gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-my-5"></div>
      <div class="gl-display-flex gl-justify-content-space-between gl-text-gray-500 gl-mb-2">
        <div>{{ $options.i18n.subtotal }}</div>
        <gl-loading-icon v-if="loading" inline class="gl-my-auto" />
        <div v-else data-testid="total-ex-vat">{{ formatAmount(totalExVat, showPrices) }}</div>
      </div>
      <div class="gl-display-flex gl-justify-content-space-between gl-text-gray-500">
        <div data-testid="tax-info-line">
          <gl-sprintf :message="taxLine">
            <template #link="{ content }">
              <gl-link
                class="gl-text-decoration-underline gl-text-gray-500"
                href="https://about.gitlab.com/handbook/tax/#indirect-taxes-management"
                target="_blank"
                data-testid="tax-help-link"
                @click="track('click_button', { label: 'tax_link' })"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </div>
        <gl-loading-icon v-if="loading" inline class="gl-my-auto" />
        <div v-else data-testid="vat">{{ taxAmount }}</div>
      </div>
    </div>
    <div class="gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-my-5"></div>
    <div class="gl-display-flex gl-justify-content-space-between gl-font-lg gl-font-weight-bold">
      <div>{{ $options.i18n.total }}</div>
      <gl-loading-icon v-if="loading" inline class="gl-my-auto" />
      <div v-else data-testid="total-amount" data-qa-selector="total_amount">
        {{ formatAmount(totalAmount, showPrices) }}
      </div>
    </div>
  </div>
</template>
