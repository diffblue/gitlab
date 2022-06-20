<script>
import { GlAlert, GlSprintf, GlLink, GlIcon } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__ } from '~/locale';
import {
  UPGRADE_STATUS_AVAILABLE,
  UPGRADE_STATUS_RECOMMENDED,
  RUNNER_INSTALL_HELP_PATH,
  RUNNER_VERSION_HELP_PATH,
} from '../constants';

export default {
  name: 'RunnerUpgradeStatusAlert',
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    GlIcon,
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
    alert() {
      if (!this.shouldShowUpgradeStatus) {
        return null;
      }

      switch (this.upgradeStatus) {
        case UPGRADE_STATUS_AVAILABLE:
          return {
            variant: 'info',
            title: s__('Runners|Upgrade available'),
          };
        case UPGRADE_STATUS_RECOMMENDED:
          return {
            variant: 'warning',
            title: s__('Runners|Upgrade recommended'),
          };
        default:
          return null;
      }
    },
  },
  RUNNER_INSTALL_HELP_PATH,
  RUNNER_VERSION_HELP_PATH,
};
</script>
<template>
  <gl-alert
    v-if="alert"
    :variant="alert.variant"
    :title="alert.title"
    :dismissible="false"
    v-bind="$attrs"
  >
    <p class="gl-mb-2">
      <gl-sprintf
        :message="
          s__(
            'Runners|Upgrade GitLab Runner to match the version of GitLab you\'re running. Both %{linkStart}major and minor versions%{linkEnd} should match.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.RUNNER_VERSION_HELP_PATH">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p class="gl-mb-0">
      <gl-link :href="$options.RUNNER_INSTALL_HELP_PATH">
        {{ s__('Runners|How do we upgrade GitLab runner?') }}
        <gl-icon name="external-link" />
      </gl-link>
    </p>
  </gl-alert>
</template>
