<script>
import { GlIcon, GlLink, GlButton } from '@gitlab/ui';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import { projectHelpPaths } from '~/usage_quotas/storage/constants';
import {
  BUY_STORAGE,
  STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
  STORAGE_STATISTICS_NAMESPACE_STORAGE_USED,
  STORAGE_STATISTICS_PURCHASED_STORAGE,
  STORAGE_STATISTICS_PURCHASED_STORAGE_USED,
} from '../constants';

export default {
  components: {
    GlIcon,
    GlLink,
    GlButton,
    StorageStatisticsCard,
  },
  inject: ['purchaseStorageUrl', 'buyAddonTargetAttr'],
  props: {
    additionalPurchasedStorageSize: {
      type: Number,
      required: false,
      default: null,
    },
    actualRepositorySizeLimit: {
      type: Number,
      required: false,
      default: null,
    },
    totalRepositorySize: {
      type: Number,
      required: false,
      default: null,
    },
    totalRepositorySizeExcess: {
      type: Number,
      required: false,
      default: null,
    },
    storageLimitEnforced: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    purchasedUsageHelpLink: projectHelpPaths.usageQuotasNamespaceStorageLimit,
    purchasedUsageHelpText: STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
    usedUsageHelpLink: projectHelpPaths.usageQuotas,
    usedUsageHelpText: STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
    purchaseButtonText: BUY_STORAGE,
    totalUsageDescription: STORAGE_STATISTICS_NAMESPACE_STORAGE_USED,
  },
  computed: {
    usedStorageAmount() {
      const {
        additionalPurchasedStorageSize,
        actualRepositorySizeLimit,
        totalRepositorySize,
      } = this;

      if (additionalPurchasedStorageSize && totalRepositorySize > actualRepositorySizeLimit) {
        return actualRepositorySizeLimit;
      }
      return totalRepositorySize;
    },
    purchasedUsageDescription() {
      if (this.additionalPurchasedStorageSize) {
        return STORAGE_STATISTICS_PURCHASED_STORAGE_USED;
      }
      return STORAGE_STATISTICS_PURCHASED_STORAGE;
    },
    repositorySizeLimit() {
      return this.actualRepositorySizeLimit;
    },
    purchasedTotalStorage() {
      return this.additionalPurchasedStorageSize;
    },
    purchasedUsedStorage() {
      // we don't want to show the used value if there's no purchased storage
      return this.additionalPurchasedStorageSize ? this.totalRepositorySizeExcess : 0;
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-sm-flex-direction-column gl-gap-5 gl-py-4">
    <storage-statistics-card
      :used-storage="usedStorageAmount"
      :total-storage="storageLimitEnforced ? repositorySizeLimit : null"
      :show-progress-bar="storageLimitEnforced"
      :loading="loading"
      data-testid="namespace-usage-card"
      data-qa-selector="namespace_usage_total"
      class="gl-flex-grow-1"
    >
      <template #description>
        {{ $options.i18n.totalUsageDescription }}

        <gl-link
          :href="$options.i18n.usedUsageHelpLink"
          target="_blank"
          class="gl-ml-2"
          :aria-label="$options.i18n.usedUsageHelpText"
        >
          <gl-icon name="question-o" />
        </gl-link>
      </template>
    </storage-statistics-card>

    <storage-statistics-card
      v-if="purchaseStorageUrl"
      :used-storage="purchasedUsedStorage"
      :total-storage="purchasedTotalStorage"
      :show-progress-bar="storageLimitEnforced"
      :loading="loading"
      data-testid="purchased-usage-card"
      data-qa-selector="purchased_usage_total"
      class="gl-flex-grow-1"
    >
      <template #actions>
        <gl-button
          :href="purchaseStorageUrl"
          target="_blank"
          category="primary"
          variant="confirm"
          data-qa-selector="purchase_more_storage"
        >
          {{ $options.i18n.purchaseButtonText }}
        </gl-button>
      </template>
      <template #description>
        {{ purchasedUsageDescription }}
        <gl-link
          :href="$options.i18n.purchasedUsageHelpLink"
          target="_blank"
          class="gl-ml-2"
          :aria-label="$options.i18n.purchasedUsageHelpText"
        >
          <gl-icon name="question-o" />
        </gl-link>
      </template>
    </storage-statistics-card>
  </div>
</template>
