<script>
import { GlBadge, GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';

import { STATE_FAILED, STATE_PASSED } from '../constants';

export default {
  components: {
    GlBadge,
    GlTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    testReport: {
      type: Object,
      required: true,
    },
    elementType: {
      type: String,
      required: false,
      default: 'div',
    },
  },
  computed: {
    testReportBadge() {
      if (this.testReport.state === STATE_PASSED) {
        return {
          variant: 'success',
          icon: 'status-success',
          text: __('satisfied'),
          tooltipTitle: __('Passed on'),
        };
      }
      if (this.testReport.state === STATE_FAILED) {
        return {
          variant: 'danger',
          icon: 'status-failed',
          text: __('failed'),
          tooltipTitle: __('Failed on'),
        };
      }
      return {
        variant: 'warning',
        icon: 'status_warning',
        text: __('missing'),
        tooltipTitle: '',
      };
    },
  },
  methods: {
    getTestReportBadgeTarget() {
      return this.$refs.testReportBadge?.$el || '';
    },
  },
};
</script>

<template>
  <component :is="elementType" class="requirement-status-badge">
    <gl-badge
      ref="testReportBadge"
      :variant="testReportBadge.variant"
      :icon="testReportBadge.icon"
      icon-size="sm"
    >
      {{ testReportBadge.text }}
    </gl-badge>
    <gl-tooltip
      v-if="testReportBadge.tooltipTitle"
      :target="getTestReportBadgeTarget"
      custom-class="requirement-status-tooltip"
    >
      <b>{{ testReportBadge.tooltipTitle }}</b>
      <div class="mt-1">{{ tooltipTitle(testReport.createdAt) }}</div>
    </gl-tooltip>
  </component>
</template>
