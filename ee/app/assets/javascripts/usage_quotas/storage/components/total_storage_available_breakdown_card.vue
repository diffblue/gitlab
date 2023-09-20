<script>
import { GlIcon, GlLink, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import { usageQuotasHelpPaths } from '~/usage_quotas/storage/constants';
import {
  STORAGE_STATISTICS_PURCHASED_STORAGE,
  STORAGE_STATISTICS_TOTAL_STORAGE,
  STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
} from '../constants';
import NumberToHumanSize from './number_to_human_size.vue';

/**
 * TotalStorageAvailableBreakdownCard
 *
 * This card is used on Namespace Usage Quotas
 * when the namespace has Namespace-level storage limits
 * https://docs.gitlab.com/ee/user/usage_quotas#namespace-storage-limit
 * It breaks down the storage available: included in the plan & purchased storage
 */

export default {
  name: 'TotalStorageAvailableBreakdownCard',
  components: { GlIcon, GlLink, GlCard, GlSkeletonLoader, NumberToHumanSize },
  inject: ['namespacePlanName'],
  props: {
    planStorageDescription: {
      type: String,
      required: true,
    },
    includedStorage: {
      type: Number,
      required: true,
    },
    purchasedStorage: {
      type: Number,
      required: true,
    },
    totalStorage: {
      type: Number,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    PURCHASED_USAGE_HELP_LINK: usageQuotasHelpPaths.usageQuotasNamespaceStorageLimit,
    STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
    STORAGE_STATISTICS_PURCHASED_STORAGE,
    STORAGE_STATISTICS_TOTAL_STORAGE,
  },
};
</script>

<template>
  <gl-card class="gl-w-full" data-testid="storage-detail-card">
    <gl-skeleton-loader v-if="loading" :height="64">
      <rect width="140" height="30" x="5" y="0" rx="4" />
      <rect width="240" height="10" x="5" y="40" rx="4" />
      <rect width="340" height="10" x="5" y="54" rx="4" />
    </gl-skeleton-loader>
    <div v-else>
      <div
        class="gl-display-flex gl-justify-content-space-between gl-gap-5"
        data-testid="storage-included-in-plan"
      >
        <div class="gl-w-80p">{{ planStorageDescription }}</div>
        <number-to-human-size class="gl-white-space-nowrap" :value="includedStorage" />
      </div>
      <div class="gl-display-flex gl-justify-content-space-between">
        <div class="gl-w-80p">
          {{ $options.i18n.STORAGE_STATISTICS_PURCHASED_STORAGE }}
          <gl-link
            :href="$options.i18n.PURCHASED_USAGE_HELP_LINK"
            target="_blank"
            class="gl-ml-2"
            :aria-label="$options.i18n.STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE"
          >
            <gl-icon name="question-o" />
          </gl-link>
        </div>
        <number-to-human-size
          class="gl-white-space-nowrap"
          :value="purchasedStorage"
          data-testid="storage-purchased"
        />
      </div>
      <hr />
      <div class="gl-display-flex gl-justify-content-space-between">
        <div class="gl-w-80p">{{ $options.i18n.STORAGE_STATISTICS_TOTAL_STORAGE }}</div>
        <number-to-human-size
          class="gl-white-space-nowrap"
          :value="totalStorage"
          data-testid="total-storage"
        />
      </div>
    </div>
  </gl-card>
</template>
