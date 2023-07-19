<script>
import { GlSprintf, GlIcon, GlLink, GlButton, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import { sprintf } from '~/locale';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import { projectHelpPaths } from '~/usage_quotas/storage/constants';
import { formatSizeAndSplit } from 'ee/usage_quotas/storage/utils';
import {
  BUY_STORAGE,
  STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
  STORAGE_STATISTICS_NAMESPACE_STORAGE_USED,
  STORAGE_INCLUDED_IN_PLAN_PROJECT_ENFORCEMENT,
  STORAGE_INCLUDED_IN_PLAN_NAMESPACE_ENFORCEMENT,
  PROJECT_ENFORCEMENT_TYPE,
  STORAGE_STATISTICS_PURCHASED_STORAGE,
  STORAGE_STATISTICS_TOTAL_STORAGE,
  NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
  PROJECT_ENFORCEMENT_TYPE_SUBTITLE,
  NAMESPACE_ENFORCEMENT_TYPE_SUBTITLE,
} from '../constants';

export default {
  components: {
    GlSprintf,
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
    'enforcementType',
    'namespacePlanStorageIncluded',
  ],
  props: {
    additionalPurchasedStorageSize: {
      type: Number,
      required: false,
      default: null,
    },
    usedStorage: {
      type: Number,
      required: false,
      default: null,
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
    enforcementTypeLearnMoreUrl() {
      return this.enforcementType === PROJECT_ENFORCEMENT_TYPE
        ? projectHelpPaths.usageQuotasProjectStorageLimit
        : projectHelpPaths.usageQuotasNamespaceStorageLimit;
    },
    enforcementTypeSubtitle() {
      const subtitle =
        this.enforcementType === PROJECT_ENFORCEMENT_TYPE
          ? PROJECT_ENFORCEMENT_TYPE_SUBTITLE
          : NAMESPACE_ENFORCEMENT_TYPE_SUBTITLE;

      return sprintf(subtitle, {
        planLimit: this.includedStorage,
      });
    },
    storageStatisticsPlanStorage() {
      if (!this.namespacePlanName) {
        return '';
      }

      const title =
        this.enforcementType === PROJECT_ENFORCEMENT_TYPE
          ? STORAGE_INCLUDED_IN_PLAN_PROJECT_ENFORCEMENT
          : STORAGE_INCLUDED_IN_PLAN_NAMESPACE_ENFORCEMENT;

      return sprintf(title, {
        planName: this.namespacePlanName,
      });
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
      return (
        Number(this.namespacePlanStorageIncluded || 0) +
        Number(this.additionalPurchasedStorageSize || 0)
      );
    },
    totalStorageFormatted() {
      const formatted = formatSizeAndSplit(this.totalStorage);
      return `${formatted.value} ${formatted.unit}`;
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
      <h3 data-testid="overview-subtitle">{{ $options.i18n.namespaceStorageOverviewSubtitle }}</h3>

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
    <p>
      <gl-sprintf :message="enforcementTypeSubtitle">
        <template #link="{ content }">
          <gl-link :href="enforcementTypeLearnMoreUrl">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <div class="gl-display-flex gl-sm-flex-direction-column gl-gap-5 gl-py-4">
      <storage-statistics-card
        :used-storage="usedStorage"
        :total-storage="totalStorage"
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
      <gl-card v-if="namespacePlanName" class="gl-w-full" data-testid="storage-detail-card">
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
            <div class="gl-white-space-nowrap">{{ includedStorage }}</div>
          </div>
          <div
            class="gl-display-flex gl-justify-content-space-between"
            data-testid="storage-purchased"
          >
            <div class="gl-w-80p">{{ $options.i18n.storageStatisticsPurchasedStorage }}</div>
            <div class="gl-white-space-nowrap">{{ purchasedTotalStorage }}</div>
          </div>
          <hr />
          <div class="gl-display-flex gl-justify-content-space-between" data-testid="total-storage">
            <div class="gl-w-80p">{{ $options.i18n.storageStatisticsTotalStorage }}</div>
            <div class="gl-white-space-nowrap">{{ totalStorageFormatted }}</div>
          </div>
        </div>
      </gl-card>
    </div>
  </div>
</template>
