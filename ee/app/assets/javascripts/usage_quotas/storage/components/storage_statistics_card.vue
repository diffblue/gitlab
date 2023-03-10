<script>
import { GlCard, GlProgressBar, GlSkeletonLoader } from '@gitlab/ui';
import { formatSizeAndSplit } from 'ee/usage_quotas/storage/utils';

export default {
  name: 'StorageStatisticsCard',
  components: { GlCard, GlProgressBar, GlSkeletonLoader },
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
    showProgressBar: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    formattedUsage() {
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
      return this.totalStorage && this.usedStorage !== null;
    },
    shouldShowProgressBar() {
      return this.showProgressBar && this.percentage !== null;
    },
  },
  methods: {
    formatSizeAndSplit,
  },
};
</script>

<template>
  <gl-card>
    <gl-skeleton-loader v-if="loading" :height="64">
      <rect width="140" height="30" x="5" y="0" rx="4" />
      <rect width="240" height="10" x="5" y="40" rx="4" />
      <rect width="340" height="10" x="5" y="54" rx="4" />
    </gl-skeleton-loader>

    <div v-else>
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
      <p class="gl-font-weight-bold gl-mb-0" data-testid="description">
        <slot name="description"></slot>
      </p>
      <gl-progress-bar v-if="shouldShowProgressBar" :value="percentage" class="gl-mt-4" />
    </div>
  </gl-card>
</template>
