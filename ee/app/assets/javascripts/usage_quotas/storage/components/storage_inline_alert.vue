<script>
import { GlAlert } from '@gitlab/ui';
import { n__, s__, sprintf } from '~/locale';
import { ALERT_THRESHOLD, ERROR_THRESHOLD, WARNING_THRESHOLD } from '../constants';
import { formatUsageSize, usageRatioToThresholdLevel } from '../utils';

export default {
  i18n: {
    lockedWithNoPurchasedStorageTitle: s__('UsageQuota|This namespace contains locked projects'),
    lockedWithNoPurchasedStorageText: s__(
      'UsageQuota|You have reached the free storage limit of %{actualRepositorySizeLimit} on %{projectsLockedText}. To unlock them, please purchase additional storage.',
    ),
    storageUsageText: s__('UsageQuota|%{percentageLeft} of purchased storage is available'),
    lockedWithPurchaseText: s__(
      'UsageQuota|You have consumed all of your additional storage, please purchase more to unlock your projects over the free %{actualRepositorySizeLimit} limit.',
    ),
    warningWithPurchaseText: s__(
      'UsageQuota|Your purchased storage is running low. To avoid locked projects, please purchase more storage.',
    ),
    infoWithPurchaseText: s__(
      'UsageQuota|When you purchase additional storage, we automatically unlock projects that were locked when you reached the %{actualRepositorySizeLimit} limit.',
    ),
  },
  components: {
    GlAlert,
  },
  props: {
    containsLockedProjects: {
      type: Boolean,
      required: true,
    },
    repositorySizeExcessProjectCount: {
      type: Number,
      required: true,
    },
    totalRepositorySizeExcess: {
      type: Number,
      required: true,
    },
    totalRepositorySize: {
      type: Number,
      required: true,
    },
    additionalPurchasedStorageSize: {
      type: Number,
      required: true,
    },
    actualRepositorySizeLimit: {
      type: Number,
      required: true,
    },
  },
  computed: {
    shouldShowAlert() {
      return this.hasPurchasedStorage() || this.containsLockedProjects;
    },
    alertText() {
      return this.hasPurchasedStorage()
        ? this.hasPurchasedStorageText()
        : this.hasNotPurchasedStorageText();
    },
    alertTitle() {
      if (!this.hasPurchasedStorage() && this.containsLockedProjects) {
        return this.$options.i18n.lockedWithNoPurchasedStorageTitle;
      }
      return sprintf(this.$options.i18n.storageUsageText, {
        percentageLeft: `${this.excessStoragePercentageLeft}%`,
      });
    },
    excessStorageRatio() {
      return this.totalRepositorySizeExcess / this.additionalPurchasedStorageSize;
    },
    excessStoragePercentageUsed() {
      return (this.excessStorageRatio * 100).toFixed(0);
    },
    excessStoragePercentageLeft() {
      return Math.max(0, 100 - this.excessStoragePercentageUsed);
    },
    thresholdLevel() {
      return usageRatioToThresholdLevel(this.excessStorageRatio);
    },
    thresholdLevelToAlertVariant() {
      if (this.thresholdLevel === ERROR_THRESHOLD || this.thresholdLevel === ALERT_THRESHOLD) {
        return 'danger';
      } else if (this.thresholdLevel === WARNING_THRESHOLD) {
        return 'warning';
      }
      return 'info';
    },
    projectsLockedText() {
      if (this.repositorySizeExcessProjectCount === 0) {
        return '';
      }
      return `${this.repositorySizeExcessProjectCount} ${n__(
        'project',
        'projects',
        this.repositorySizeExcessProjectCount,
      )}`;
    },
  },
  methods: {
    hasPurchasedStorage() {
      return this.additionalPurchasedStorageSize > 0;
    },
    formatSize(size) {
      return formatUsageSize(size);
    },
    hasPurchasedStorageText() {
      if (this.thresholdLevel === ERROR_THRESHOLD) {
        return sprintf(this.$options.i18n.lockedWithPurchaseText, {
          actualRepositorySizeLimit: this.formatSize(this.actualRepositorySizeLimit),
        });
      } else if (
        this.thresholdLevel === WARNING_THRESHOLD ||
        this.thresholdLevel === ALERT_THRESHOLD
      ) {
        return this.$options.i18n.warningWithPurchaseText;
      }
      return sprintf(this.$options.i18n.infoWithPurchaseText, {
        actualRepositorySizeLimit: this.formatSize(this.actualRepositorySizeLimit),
      });
    },
    hasNotPurchasedStorageText() {
      if (this.thresholdLevel === ERROR_THRESHOLD) {
        return sprintf(this.$options.i18n.lockedWithNoPurchasedStorageText, {
          actualRepositorySizeLimit: this.formatSize(this.actualRepositorySizeLimit),
          projectsLockedText: this.projectsLockedText,
        });
      }
      return '';
    },
  },
};
</script>
<template>
  <gl-alert
    v-if="shouldShowAlert"
    class="gl-mt-5"
    :variant="thresholdLevelToAlertVariant"
    :dismissible="false"
    :title="alertTitle"
  >
    {{ alertText }}
  </gl-alert>
</template>
