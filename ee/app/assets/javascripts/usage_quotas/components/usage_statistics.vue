<script>
import { GlProgressBar } from '@gitlab/ui';

export default {
  name: 'UsageStatistics',
  components: {
    GlProgressBar,
  },
  props: {
    percentage: {
      type: Number,
      required: false,
      default: null,
    },
    usageUnit: {
      type: String,
      required: false,
      default: null,
    },
    usageValue: {
      type: String,
      required: false,
      default: null,
    },
    totalUnit: {
      type: String,
      required: false,
      default: null,
    },
    totalValue: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    shouldShowProgressBar() {
      return this.percentage !== null;
    },
  },
};
</script>

<template>
  <div>
    <section class="gl-display-flex gl-justify-content-space-between gl-mb-3">
      <section>
        <p
          v-if="usageValue"
          class="gl-font-size-h-display gl-font-weight-bold gl-mb-0"
          data-testid="usage"
        >
          {{ usageValue
          }}<span v-if="usageUnit" data-testid="usage-unit" class="gl-font-lg">{{
            usageUnit
          }}</span>
          <span v-if="totalValue" data-testid="total">
            / {{ totalValue
            }}<span v-if="totalUnit" class="gl-font-lg" data-testid="total-unit">{{
              totalUnit
            }}</span>
          </span>
        </p>
        <slot name="description"></slot>
      </section>
      <div class="gl-align-self-top">
        <slot name="actions"></slot>
      </div>
    </section>
    <gl-progress-bar v-if="shouldShowProgressBar" class="gl-mt-5" :value="percentage" />
    <slot name="additional-info"></slot>
  </div>
</template>
