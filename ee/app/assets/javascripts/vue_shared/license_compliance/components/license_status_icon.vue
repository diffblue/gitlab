<script>
import { GlIcon } from '@gitlab/ui';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/ci/reports/constants';

export default {
  name: 'LicenseStatusIcon',
  components: {
    GlIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
    statusIconSize: {
      type: Number,
      required: false,
      default: 12,
    },
  },
  computed: {
    iconName() {
      if (this.isStatusFailed) {
        return 'status-failed';
      } else if (this.isStatusSuccess) {
        return 'status-success';
      }

      return 'status-alert';
    },
    isStatusFailed() {
      return this.status === STATUS_FAILED;
    },
    isStatusSuccess() {
      return this.status === STATUS_SUCCESS;
    },
    isStatusNeutral() {
      return this.status === STATUS_NEUTRAL;
    },
  },
};
</script>
<template>
  <div
    :class="{
      failed: isStatusFailed,
      success: isStatusSuccess,
      neutral: isStatusNeutral,
    }"
    class="report-block-list-icon"
  >
    <gl-icon
      class="gl-mb-1"
      :name="iconName"
      :size="statusIconSize"
      :data-qa-selector="`status_${status}_icon`"
    />
  </div>
</template>
