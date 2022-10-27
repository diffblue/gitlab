<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import { UPGRADE_STATUS_AVAILABLE, UPGRADE_STATUS_RECOMMENDED } from '../constants';

export default {
  name: 'RunnerUpgradeStatusIcon',
  components: {
    GlIcon,
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
    icon() {
      if (!this.shouldShowUpgradeStatus) {
        return null;
      }

      switch (this.upgradeStatus) {
        case UPGRADE_STATUS_AVAILABLE:
          return {
            class: 'gl-text-blue-500',
            tooltip: s__('Runners|An upgrade is available for this runner'),
          };
        case UPGRADE_STATUS_RECOMMENDED:
          return {
            class: 'gl-text-orange-500',
            tooltip: s__('Runners|An upgrade is recommended for this runner'),
          };
        default:
          return null;
      }
    },
  },
};
</script>
<template>
  <gl-icon v-if="icon" v-gl-tooltip="icon.tooltip" :class="icon.class" name="upgrade" />
</template>
