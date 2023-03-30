<script>
import { GlLink, GlIcon, GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import formattingMixins from 'ee/subscriptions/new/formatting_mixins';
import { formatNumber } from '~/locale';
import {
  I18N_SUMMARY_DATES,
  I18N_SUMMARY_QUANTITY,
  I18N_SUMMARY_SUBTOTAL,
  I18N_SUMMARY_TAX,
  I18N_SUMMARY_TAX_NOTE,
  I18N_SUMMARY_TOTAL,
  I18N_STORAGE_TOOLTIP_NOTE,
} from '../../constants';

export default {
  components: {
    GlLink,
    GlSprintf,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    subscriptionEndDate: {
      type: String,
      required: false,
      default: '',
    },
    hasExpiration: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      startDate: new Date(),
    };
  },
  computed: {
    endDate() {
      return (
        this.subscriptionEndDate ||
        new Date(this.startDate).setFullYear(this.startDate.getFullYear() + 1)
      );
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
    formattedPrice() {
      return formatNumber(this.selectedPlanPrice);
    },
    renderedAmount() {
      return this.totalExVat ? this.formatAmount(this.totalExVat, this.hasPositiveQuantity) : '-';
    },
  },
  i18n: {
    quantity: I18N_SUMMARY_QUANTITY,
    dates: I18N_SUMMARY_DATES,
    subtotal: I18N_SUMMARY_SUBTOTAL,
    tax: I18N_SUMMARY_TAX,
    taxNote: I18N_SUMMARY_TAX_NOTE,
    total: I18N_SUMMARY_TOTAL,
    tooltipNote: I18N_STORAGE_TOOLTIP_NOTE,
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between gl-font-weight-bold gl-mb-3">
      <div data-testid="selected-plan">
        {{ selectedPlanText }}
        <span v-if="hasPositiveQuantity" data-testid="quantity">{{
          sprintf($options.i18n.quantity, { quantity })
        }}</span>
      </div>
      <div>
        {{ renderedAmount }}
      </div>
    </div>
    <div class="gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-pb-5 gl-mb-5">
      <div class="gl-text-gray-500" data-testid="price-per-unit">
        <slot name="price-per-unit" :price="formattedPrice"></slot>
      </div>
      <div v-if="hasExpiration" class="gl-text-gray-500" data-testid="subscription-period">
        {{
          sprintf($options.i18n.dates, {
            startDate: formatDate(startDate),
            endDate: formatDate(endDate),
          })
        }}
        <gl-icon
          v-if="subscriptionEndDate"
          v-gl-tooltip.right
          :title="$options.i18n.tooltipNote"
          :aria-label="$options.i18n.tooltipNote"
          role="tooltip"
          name="question-o"
        />
      </div>
    </div>
    <div class="gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-pb-5 gl-mb-5">
      <div class="gl-display-flex gl-justify-content-space-between gl-text-gray-500 gl-mb-2">
        <div>{{ $options.i18n.subtotal }}</div>
        <div data-testid="total-ex-vat">
          {{ renderedAmount }}
        </div>
      </div>
      <div class="gl-display-flex gl-justify-content-space-between gl-text-gray-500">
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
        <div data-testid="vat">{{ taxAmount }}</div>
      </div>
    </div>
    <div class="gl-display-flex gl-justify-content-space-between gl-font-weight-bold gl-font-lg">
      <div>{{ $options.i18n.total }}</div>
      <div data-testid="total-amount">
        {{ renderedAmount }}
      </div>
    </div>
  </div>
</template>
