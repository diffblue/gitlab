<script>
import { GlProgressBar } from '@gitlab/ui';
import { formatSizeAndSplit } from 'ee/usage_quotas/storage/utils';

export default {
  name: 'StorageStatisticsCard',
  components: { GlProgressBar },
  props: {
    totalStorage: {
      type: Number,
      required: false,
      default: null,
    },
    usedStorage: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    formattedUsage() {
      // we want to show the usage only if there's purchased storage
      if (this.totalStorage === null) {
        return null;
      }
      return this.formatSizeAndSplit(this.usedStorage);
    },
    formattedTotal() {
      return this.formatSizeAndSplit(this.totalStorage);
    },
    percentage() {
      // don't show the progress bar if there's no total storage
      if (!this.totalStorage || this.usedStorage === null) {
        return null;
      }
      return Math.min(Math.round((this.usedStorage / this.totalStorage) * 100), 100);
    },
    usageValue() {
      if (!this.totalStorage && !this.usedStorage) {
        // if there is no total storage and no used storage, we want
        // to show `0` instead of the formatted `0.0`
        return '0';
      }
      return this.formattedUsage?.value;
    },
    usageUnit() {
      return this.formattedUsage?.unit;
    },
    totalValue() {
      return this.formattedTotal?.value;
    },
    totalUnit() {
      return this.formattedTotal?.unit;
    },
    shouldRenderTotalBlock() {
      // only show the total block if the used and total storage are not 0
      return this.usedStorage && this.totalStorage;
    },
  },
  methods: {
    formatSizeAndSplit,
  },
};
</script>

<template>
  <div
    class="gl-bg-white gl-border-1 gl-border-gray-100 gl-border-solid gl-p-5 gl-rounded-base"
    data-testid="container"
  >
    <div class="gl-display-flex gl-justify-content-space-between">
      <p class="gl-font-size-h-display gl-font-weight-bold gl-mb-3" data-testid="denominator">
        {{ usageValue }}
        <span class="gl-font-lg">{{ usageUnit }}</span>
        <span v-if="shouldRenderTotalBlock" data-testid="denominator-total">
          /
          {{ totalValue }}
          <span class="gl-font-lg">{{ totalUnit }}</span>
        </span>
      </p>

      <div data-testid="actions">
        <slot name="actions"></slot>
      </div>
    </div>
    <p class="gl-font-weight-bold" data-testid="description">
      <slot name="description"></slot>
    </p>
    <gl-progress-bar v-if="percentage !== null" :value="percentage" />
  </div>
</template>
