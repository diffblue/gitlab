<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  UPGRADE_STATUS_AVAILABLE,
  UPGRADE_STATUS_RECOMMENDED,
  I18N_UPGRADE_STATUS_AVAILABLE,
  I18N_UPGRADE_STATUS_RECOMMENDED,
  I18N_UPGRADE_STATUS_AVAILABLE_TOOLTIP,
  I18N_UPGRADE_STATUS_RECOMMENDED_TOOLTIP,
} from '../constants';

export default {
  name: 'RunnerUpgradeStatusBadge',
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    runner: {
      required: true,
      type: Object,
    },
    size: {
      type: String,
      default: null,
      required: false,
    },
  },
  computed: {
    shouldShowUpgradeStatus() {
      return (
        this.glFeatures?.runnerUpgradeManagement ||
        this.glFeatures?.runnerUpgradeManagementForNamespace
      );
    },
    upgradeStatus() {
      return this.runner.upgradeStatus;
    },
    badge() {
      if (!this.shouldShowUpgradeStatus) {
        return null;
      }

      switch (this.upgradeStatus) {
        case UPGRADE_STATUS_AVAILABLE:
          return {
            variant: 'info',
            label: I18N_UPGRADE_STATUS_AVAILABLE,
            tooltip: I18N_UPGRADE_STATUS_AVAILABLE_TOOLTIP,
          };
        case UPGRADE_STATUS_RECOMMENDED:
          return {
            variant: 'warning',
            label: I18N_UPGRADE_STATUS_RECOMMENDED,
            tooltip: I18N_UPGRADE_STATUS_RECOMMENDED_TOOLTIP,
          };
        default:
          return null;
      }
    },
    icon() {
      return this.size === 'sm' ? null : 'upgrade';
    },
  },
};
</script>
<template>
  <gl-badge
    v-if="badge"
    v-gl-tooltip="badge.tooltip"
    :variant="badge.variant"
    :size="size"
    :icon="icon"
    v-bind="$attrs"
  >
    {{ badge.label }}
  </gl-badge>
</template>
