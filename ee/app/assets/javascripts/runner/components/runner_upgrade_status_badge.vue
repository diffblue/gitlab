<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import { UPGRADE_STATUS_AVAILABLE, UPGRADE_STATUS_RECOMMENDED } from '../constants';

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
            label: s__('Runners|upgrade available'),
            tooltip: s__('Runners|A new version is available'),
          };
        case UPGRADE_STATUS_RECOMMENDED:
          return {
            variant: 'warning',
            label: s__('Runners|upgrade recommended'),
            tooltip: s__('Runners|This runner is outdated, an upgrade is recommended'),
          };
        default:
          return null;
      }
    },
  },
};
</script>
<template>
  <gl-badge v-if="badge" v-gl-tooltip="badge.tooltip" :variant="badge.variant" v-bind="$attrs">
    {{ badge.label }}
  </gl-badge>
</template>
