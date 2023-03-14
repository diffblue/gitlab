<script>
import {
  GlLink,
  GlIcon,
  GlTooltipDirective,
  GlButton,
  GlProgressBar,
  GlSkeletonLoader,
} from '@gitlab/ui';

export default {
  name: 'StatisticsCard',
  components: { GlLink, GlIcon, GlButton, GlProgressBar, GlSkeletonLoader },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    usageValue: {
      type: String,
      required: false,
      default: null,
    },
    usageUnit: {
      type: String,
      required: false,
      default: null,
    },
    totalValue: {
      type: String,
      required: false,
      default: null,
    },
    totalUnit: {
      type: String,
      required: false,
      default: null,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    helpLink: {
      type: String,
      required: false,
      default: null,
    },
    helpLabel: {
      type: String,
      required: false,
      default: null,
    },
    helpTooltip: {
      type: String,
      required: false,
      default: null,
    },
    percentage: {
      type: Number,
      required: false,
      default: null,
    },
    purchaseButtonLink: {
      type: String,
      required: false,
      default: null,
    },
    purchaseButtonText: {
      type: String,
      required: false,
      default: null,
    },
    cssClass: {
      type: String,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div
    class="gl-bg-white gl-border-1 gl-border-gray-100 gl-border-solid gl-p-5 gl-rounded-base"
    data-testid="container"
    :class="cssClass"
  >
    <div v-if="loading" class="gl-lg-w-half">
      <gl-skeleton-loader :height="50">
        <rect width="140" height="30" x="5" y="0" rx="4" />
        <rect width="240" height="10" x="5" y="40" rx="4" />
      </gl-skeleton-loader>
    </div>
    <template v-else>
      <div class="gl-display-flex gl-justify-content-space-between">
        <p
          v-if="usageValue"
          class="gl-font-size-h-display gl-font-weight-bold gl-mb-3"
          data-testid="denominator"
        >
          {{ usageValue }}
          <span v-if="usageUnit" data-testid="denominator-usage-unit" class="gl-font-lg">{{
            usageUnit
          }}</span>
          <span v-if="totalValue" data-testid="denominator-total">
            /
            {{ totalValue }}
            <span v-if="totalUnit" class="gl-font-lg" data-testid="denominator-total-unit">{{
              totalUnit
            }}</span>
          </span>
        </p>

        <div>
          <gl-button
            v-if="purchaseButtonLink && purchaseButtonText"
            :href="purchaseButtonLink"
            category="primary"
            variant="confirm"
          >
            {{ purchaseButtonText }}
          </gl-button>
        </div>
      </div>
      <p v-if="description" class="gl-font-weight-bold gl-mb-0" data-testid="description">
        {{ description }}
        <gl-link
          v-if="helpLink"
          v-gl-tooltip
          :href="helpLink"
          target="_blank"
          class="gl-ml-2"
          :title="helpTooltip"
          :aria-label="helpLabel"
        >
          <gl-icon name="question-o" />
        </gl-link>
      </p>
      <gl-progress-bar v-if="percentage !== null" class="gl-mt-5" :value="percentage" />
    </template>
  </div>
</template>
