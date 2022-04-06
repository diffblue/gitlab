<script>
import { GlIcon, GlLink, GlButton } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import StorageStatisticsCard from 'ee/usage_quotas/components/storage_statistics_card.vue';

export default {
  components: {
    GlIcon,
    GlLink,
    GlButton,
    StorageStatisticsCard,
  },
  inject: ['purchaseStorageUrl', 'buyAddonTargetAttr'],
  props: {
    rootStorageStatistics: {
      required: true,
      type: Object,
    },
  },
  i18n: {
    purchasedUsageHelpLink: helpPagePath('user/usage_quotas'),
    purchasedUsageHelpText: s__('UsageQuota|Learn more about usage quotas.'),
    usedUsageHelpLink: helpPagePath('user/usage_quotas'),
    usedUsageHelpText: s__('UsageQuota|Learn more about usage quotas.'),
    purchaseButtonText: s__('UsageQuota|Buy storage'),
    totalUsageDescription: s__('UsageQuota|Namespace storage used'),
  },
  computed: {
    usedStorageAmount() {
      const {
        additionalPurchasedStorageSize,
        actualRepositorySizeLimit,
        totalRepositorySize,
      } = this.rootStorageStatistics;

      if (additionalPurchasedStorageSize && totalRepositorySize > actualRepositorySizeLimit) {
        return actualRepositorySizeLimit;
      }
      return totalRepositorySize;
    },
    purchasedUsageDescription() {
      if (this.rootStorageStatistics.additionalPurchasedStorageSize) {
        return s__('UsageQuota|Purchased storage used');
      }
      return s__('UsageQuota|Purchased storage');
    },
    repositorySizeLimit() {
      return Number(this.rootStorageStatistics.actualRepositorySizeLimit);
    },
    purchasedTotalStorage() {
      return Number(this.rootStorageStatistics.additionalPurchasedStorageSize);
    },
    purchasedUsedStorage() {
      // we don't want to show the used value if there's no purchased storage
      return this.rootStorageStatistics.additionalPurchasedStorageSize
        ? Number(this.rootStorageStatistics.totalRepositorySizeExcess)
        : 0;
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-sm-flex-direction-column gl-py-5">
    <storage-statistics-card
      :used-storage="usedStorageAmount"
      :total-storage="repositorySizeLimit"
      data-testid="namespace-usage-card"
      class="gl-w-half gl-md-mr-5"
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
      data-testid="purchased-usage-card"
      class="gl-w-half"
    >
      <template #actions>
        <gl-button :href="purchaseStorageUrl" target="_blank" category="primary" variant="confirm">
          {{ $options.i18n.purchaseButtonText }}
        </gl-button>
      </template>
      <template #description>
        {{ purchasedUsageDescription }}
        <gl-link
          :href="$options.purchasedUsageHelpLink"
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
