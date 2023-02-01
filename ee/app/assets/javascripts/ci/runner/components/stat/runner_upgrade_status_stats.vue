<script>
import { GlPopover } from '@gitlab/ui';
import RunnerSingleStat from '~/ci/runner/components/stat/runner_single_stat.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { UPGRADE_STATUS_AVAILABLE, UPGRADE_STATUS_RECOMMENDED } from '../../constants';

export default {
  components: {
    GlPopover,
    RunnerSingleStat,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    scope: {
      type: String,
      required: true,
    },
    variables: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    shouldShowUpgradeStatus() {
      return (
        this.glFeatures?.runnerUpgradeManagement ||
        this.glFeatures?.runnerUpgradeManagementForNamespace
      );
    },
  },
  methods: {
    statVariables(upgradeStatus) {
      return { ...this.variables, upgradeStatus };
    },
    shouldSkipStat(upgradeStatus) {
      // Upgrade status are mutually exclusive, skip displaying this total
      // when filtering by an upgrade status different to this one
      return this.variables.upgradeStatus && this.variables.upgradeStatus !== upgradeStatus;
    },
  },
  UPGRADE_STATUS_AVAILABLE,
  UPGRADE_STATUS_RECOMMENDED,
};
</script>
<template>
  <div v-if="shouldShowUpgradeStatus">
    <runner-single-stat
      id="status-available-stat"
      tabindex="0"
      :scope="scope"
      :title="s__('Runners|Upgrade available')"
      :variables="statVariables($options.UPGRADE_STATUS_AVAILABLE)"
      :skip="shouldSkipStat($options.UPGRADE_STATUS_AVAILABLE)"
      variant="info"
      meta-icon="upgrade"
      class="gl-px-5"
    />
    <gl-popover target="status-available-stat" placement="bottom">
      {{ s__('Runners|Minor version upgrades are available.') }}
    </gl-popover>

    <runner-single-stat
      id="status-recommended-stat"
      tabindex="0"
      :scope="scope"
      :title="s__('Runners|Upgrade recommended')"
      :variables="statVariables($options.UPGRADE_STATUS_RECOMMENDED)"
      :skip="shouldSkipStat($options.UPGRADE_STATUS_RECOMMENDED)"
      variant="warning"
      meta-icon="upgrade"
      class="gl-px-5"
    />
    <gl-popover target="status-recommended-stat" placement="bottom">
      {{ s__('Runners|Security or compatibility upgrades are recommended.') }}
    </gl-popover>
  </div>
</template>
