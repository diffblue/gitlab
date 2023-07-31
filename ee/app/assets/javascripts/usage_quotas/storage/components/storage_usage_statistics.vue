<script>
import { GlSprintf, GlIcon, GlLink, GlButton, GlCard, GlSkeletonLoader } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import StorageStatisticsCard from 'ee/usage_quotas/storage/components/storage_statistics_card.vue';
import { usageQuotasHelpPaths } from '~/usage_quotas/storage/constants';
import {
  BUY_STORAGE,
  STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
  STORAGE_INCLUDED_IN_PLAN_PROJECT_ENFORCEMENT,
  STORAGE_INCLUDED_IN_PLAN_NAMESPACE_ENFORCEMENT,
  PROJECT_ENFORCEMENT_TYPE,
  STORAGE_STATISTICS_PURCHASED_STORAGE,
  STORAGE_STATISTICS_TOTAL_STORAGE,
  NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
  PROJECT_ENFORCEMENT_TYPE_SUBTITLE,
  NAMESPACE_ENFORCEMENT_TYPE_SUBTITLE,
} from '../constants';
import NumberToHumanSize from './number_to_human_size.vue';

export default {
  components: {
    GlSprintf,
    GlIcon,
    GlLink,
    GlButton,
    GlCard,
    GlSkeletonLoader,
    StorageStatisticsCard,
    NumberToHumanSize,
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
    purchasedUsageHelpLink: usageQuotasHelpPaths.usageQuotasNamespaceStorageLimit,
    purchasedUsageHelpText: STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
    usedUsageHelpLink: usageQuotasHelpPaths.usageQuotas,
    usedUsageHelpText: STORAGE_STATISTICS_USAGE_QUOTA_LEARN_MORE,
    purchaseButtonText: BUY_STORAGE,
    namespaceStorageOverviewSubtitle: NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
    storageStatisticsPurchasedStorage: STORAGE_STATISTICS_PURCHASED_STORAGE,
    storageStatisticsTotalStorage: STORAGE_STATISTICS_TOTAL_STORAGE,
  },
  computed: {
    enforcementTypeLearnMoreUrl() {
      return this.enforcementType === PROJECT_ENFORCEMENT_TYPE
        ? usageQuotasHelpPaths.usageQuotasProjectStorageLimit
        : usageQuotasHelpPaths.usageQuotasNamespaceStorageLimit;
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
      return numberToHumanSize(this.namespacePlanStorageIncluded || 0, 1);
    },
    purchasedTotalStorage() {
      if (!this.additionalPurchasedStorageSize) {
        return 0;
      }

      return numberToHumanSize(this.additionalPurchasedStorageSize || 0, 1);
    },
    totalStorage() {
      return (
        Number(this.namespacePlanStorageIncluded || 0) +
        Number(this.additionalPurchasedStorageSize || 0)
      );
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
    <p class="gl-mb-0">
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
        data-qa-selector="namespace_usage_total"
        class="gl-w-full"
      />
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
            <div class="gl-w-80p">
              {{ $options.i18n.storageStatisticsPurchasedStorage }}
              <gl-link
                :href="$options.i18n.purchasedUsageHelpLink"
                target="_blank"
                class="gl-ml-2"
                :aria-label="$options.i18n.purchasedUsageHelpText"
              >
                <gl-icon name="question-o" />
              </gl-link>
            </div>
            <div class="gl-white-space-nowrap">{{ purchasedTotalStorage }}</div>
          </div>
          <hr />
          <div class="gl-display-flex gl-justify-content-space-between" data-testid="total-storage">
            <div class="gl-w-80p">{{ $options.i18n.storageStatisticsTotalStorage }}</div>
            <number-to-human-size class="gl-white-space-nowrap" :value="totalStorage" />
          </div>
        </div>
      </gl-card>
    </div>
  </div>
</template>
