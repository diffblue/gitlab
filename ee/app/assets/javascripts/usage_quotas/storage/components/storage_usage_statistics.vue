<script>
import { GlIcon, GlLink, GlButton, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import { sprintf } from '~/locale';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import { projectHelpPaths } from '~/usage_quotas/storage/constants';
import { formatSizeAndSplit } from 'ee/usage_quotas/storage/utils';
import {
  BUY_STORAGE,
  STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
  STORAGE_STATISTICS_NAMESPACE_STORAGE_USED,
  STORAGE_STATISTICS_PLAN_STORAGE,
  STORAGE_STATISTICS_PURCHASED_STORAGE,
  STORAGE_STATISTICS_TOTAL_STORAGE,
  NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
} from '../constants';

export default {
  components: {
    GlIcon,
    GlLink,
    GlButton,
    GlCard,
    GlSkeletonLoader,
    StorageStatisticsCard,
  },
  inject: [
    'purchaseStorageUrl',
    'buyAddonTargetAttr',
    'namespacePlanName',
    'namespacePlanStorageIncluded',
  ],
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
    namespaceStorageOverviewSubtitle: NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
    storageStatisticsPurchasedStorage: STORAGE_STATISTICS_PURCHASED_STORAGE,
    storageStatisticsTotalStorage: STORAGE_STATISTICS_TOTAL_STORAGE,
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
    storageStatisticsPlanStorage() {
      if (!this.namespacePlanName) {
        return '';
      }

      return sprintf(STORAGE_STATISTICS_PLAN_STORAGE, {
        planName: this.namespacePlanName,
      });
    },
    repositorySizeLimit() {
      return this.actualRepositorySizeLimit;
    },
    includedStorage() {
      const formatted = formatSizeAndSplit(this.namespacePlanStorageIncluded || 0);

      return `${formatted.value} ${formatted.unit}`;
    },
    purchasedTotalStorage() {
      const formatted = formatSizeAndSplit(this.additionalPurchasedStorageSize || 0);

      return `${formatted.value} ${formatted.unit}`;
    },
    totalStorage() {
      const totalStorage =
        Number(this.namespacePlanStorageIncluded || 0) +
        Number(this.additionalPurchasedStorageSize || 0);
      const formatted = formatSizeAndSplit(totalStorage);

      return `${formatted.value} ${formatted.unit}`;
    },
  },
};
</script>
<template>
  <div class="gl-py-4">
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
      <h4 data-testid="overview-subtitle">{{ $options.i18n.namespaceStorageOverviewSubtitle }}</h4>

      <gl-button
        v-if="purchaseStorageUrl"
        :href="purchaseStorageUrl"
        :target="buyAddonTargetAttr"
        category="primary"
        variant="confirm"
        data-qa-selector="purchase_more_storage"
      >
        {{ $options.i18n.purchaseButtonText }}
      </gl-button>
    </div>
    <div class="gl-display-flex gl-sm-flex-direction-column gl-gap-5 gl-py-4">
      <storage-statistics-card
        :used-storage="usedStorageAmount"
        :total-storage="storageLimitEnforced ? repositorySizeLimit : null"
        :show-progress-bar="storageLimitEnforced"
        :loading="loading"
        data-testid="namespace-usage-card"
        data-qa-selector="namespace_usage_total"
        class="gl-w-full"
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
      <gl-card
        v-if="namespacePlanName"
        class="gl-w-full gl-lg-w-50p"
        data-testid="storage-detail-card"
      >
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
            <div class="gl-w-80p">{{ storageStatisticsPlanStorage }}</div>
            <div>{{ includedStorage }}</div>
          </div>
          <div
            class="gl-display-flex gl-justify-content-space-between"
            data-testid="storage-purchased"
          >
            <div class="gl-w-80p">{{ $options.i18n.storageStatisticsPurchasedStorage }}</div>
            <div>{{ purchasedTotalStorage }}</div>
          </div>
          <hr />
          <div class="gl-display-flex gl-justify-content-space-between" data-testid="total-storage">
            <div class="gl-w-80p">{{ $options.i18n.storageStatisticsTotalStorage }}</div>
            <div>{{ totalStorage }}</div>
          </div>
        </div>
      </gl-card>
    </div>
  </div>
</template>
