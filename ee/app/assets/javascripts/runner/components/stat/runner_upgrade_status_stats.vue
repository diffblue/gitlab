<script>
import { s__ } from '~/locale';
import RunnerSingleStat from '~/runner/components/stat/runner_single_stat.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { UPGRADE_STATUS_AVAILABLE, UPGRADE_STATUS_RECOMMENDED } from '../../constants';

export default {
  components: {
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
    stats() {
      return [
        {
          key: UPGRADE_STATUS_RECOMMENDED,
          props: {
            skip: this.shouldSkipStat(UPGRADE_STATUS_RECOMMENDED),
            variables: { ...this.variables, upgradeStatus: UPGRADE_STATUS_RECOMMENDED },
            variant: 'warning',
            title: s__('Runners|Outdated'),
            metaText: s__('Runners|recommended'),
          },
        },
        {
          key: UPGRADE_STATUS_AVAILABLE,
          props: {
            skip: this.shouldSkipStat(UPGRADE_STATUS_AVAILABLE),
            variables: { ...this.variables, upgradeStatus: UPGRADE_STATUS_AVAILABLE },
            variant: 'info',
            title: s__('Runners|Outdated'),
            metaText: s__('Runners|available'),
          },
        },
      ];
    },
  },
  methods: {
    shouldSkipStat(upgradeStatus) {
      // Upgrade status are mutually exclusive, skip displaying this total
      // when filtering by an upgrade status different to this one
      return this.variables.upgradeStatus && this.variables.upgradeStatus !== upgradeStatus;
    },
  },
};
</script>
<template>
  <div v-if="shouldShowUpgradeStatus">
    <runner-single-stat
      v-for="stat in stats"
      :key="stat.key"
      :scope="scope"
      v-bind="stat.props"
      class="gl-px-5"
    />
  </div>
</template>
