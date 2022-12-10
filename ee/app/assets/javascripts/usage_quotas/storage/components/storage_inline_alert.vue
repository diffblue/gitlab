<script>
import { GlAlert } from '@gitlab/ui';
import { n__, s__, sprintf } from '~/locale';
import { ALERT_THRESHOLD, ERROR_THRESHOLD } from '../constants';
import { formatUsageSize, usageRatioToThresholdLevel } from '../utils';

export default {
  i18n: {
    lockedWithNoPurchasedStorageText: s__(
      'UsageQuota|You have reached the free storage limit on %{projectsLockedText}. To unlock them, purchase additional storage.',
    ),
    lockedWithPurchaseText: s__(
      'UsageQuota|You have consumed all of your additional storage. Purchase more to unlock projects over the limit.',
    ),
    warningWithPurchaseText: s__(
      'UsageQuota|Your purchased storage is running low. To avoid locked projects, purchase more storage.',
    ),
    infoWithPurchaseText: s__(
      'UsageQuota|When you purchase additional storage, we automatically unlock projects that were locked if the storage limit was reached.',
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
        return this.$options.i18n.lockedWithPurchaseText;
      } else if (this.thresholdLevel === ALERT_THRESHOLD) {
        return this.$options.i18n.warningWithPurchaseText;
      }
      return this.$options.i18n.infoWithPurchaseText;
    },
    hasNotPurchasedStorageText() {
      if (this.thresholdLevel === ERROR_THRESHOLD) {
        return sprintf(this.$options.i18n.lockedWithNoPurchasedStorageText, {
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
  >
    {{ alertText }}
  </gl-alert>
</template>
