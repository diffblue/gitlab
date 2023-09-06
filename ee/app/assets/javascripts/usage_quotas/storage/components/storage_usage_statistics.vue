<script>
import { GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { usageQuotasHelpPaths } from '~/usage_quotas/storage/constants';
import {
  BUY_STORAGE,
  STORAGE_INCLUDED_IN_PLAN_PROJECT_ENFORCEMENT,
  STORAGE_INCLUDED_IN_PLAN_NAMESPACE_ENFORCEMENT,
  NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
  PROJECT_ENFORCEMENT_TYPE_SUBTITLE,
  NAMESPACE_ENFORCEMENT_TYPE_SUBTITLE,
} from '../constants';
import StorageStatisticsCard from './storage_statistics_card.vue';
import TotalStorageAvailableBreakdownCard from './total_storage_available_breakdown_card.vue';

export default {
  components: {
    GlSprintf,
    GlLink,
    GlButton,
    StorageStatisticsCard,
    TotalStorageAvailableBreakdownCard,
  },
  inject: [
    'purchaseStorageUrl',
    'buyAddonTargetAttr',
    'namespacePlanName',
    'isNamespaceUnderProjectLimits',
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
    purchaseButtonText: BUY_STORAGE,
    namespaceStorageOverviewSubtitle: NAMESPACE_STORAGE_OVERVIEW_SUBTITLE,
  },
  computed: {
    enforcementTypeLearnMoreUrl() {
      return this.isNamespaceUnderProjectLimits
        ? usageQuotasHelpPaths.usageQuotasProjectStorageLimit
        : usageQuotasHelpPaths.usageQuotasNamespaceStorageLimit;
    },
    enforcementTypeSubtitle() {
      const subtitle = this.isNamespaceUnderProjectLimits
        ? PROJECT_ENFORCEMENT_TYPE_SUBTITLE
        : NAMESPACE_ENFORCEMENT_TYPE_SUBTITLE;

      return sprintf(subtitle, {
        planLimit: numberToHumanSize(this.includedStorage, 1),
      });
    },
    planStorageDescription() {
      if (!this.namespacePlanName) {
        return '';
      }

      const title = this.isNamespaceUnderProjectLimits
        ? STORAGE_INCLUDED_IN_PLAN_PROJECT_ENFORCEMENT
        : STORAGE_INCLUDED_IN_PLAN_NAMESPACE_ENFORCEMENT;

      return sprintf(title, {
        planName: this.namespacePlanName,
      });
    },
    includedStorage() {
      return Number(this.namespacePlanStorageIncluded || 0);
    },
    purchasedStorage() {
      return Number(this.additionalPurchasedStorageSize || 0);
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
        data-testid="purchase-more-storage"
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
        :plan-storage-description="planStorageDescription"
        :used-storage="usedStorage"
        :total-storage="totalStorage"
        :loading="loading"
        data-testid="namespace-usage-total"
        class="gl-w-full"
      />
      <total-storage-available-breakdown-card
        v-if="namespacePlanName"
        :plan-storage-description="planStorageDescription"
        :included-storage="includedStorage"
        :purchased-storage="purchasedStorage"
        :total-storage="totalStorage"
        :loading="loading"
      />
    </div>
  </div>
</template>
