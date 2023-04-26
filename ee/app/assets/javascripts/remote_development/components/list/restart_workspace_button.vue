<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { WORKSPACE_DESIRED_STATES, WORKSPACE_STATES } from '../../constants';

export const i18n = {
  restartingWorkspaceTooltip: s__('Workspaces|Restarting'),
  restartWorkspaceTooltip: s__('Workspaces|Restart'),
};

const ACTUAL_STATE_TO_DESIRED_STATE_VISIBILITY_MAP = {
  [WORKSPACE_STATES.running]: [
    WORKSPACE_DESIRED_STATES.restarting,
    WORKSPACE_DESIRED_STATES.running,
  ],
  [WORKSPACE_STATES.stopped]: [
    WORKSPACE_DESIRED_STATES.restarting,
    WORKSPACE_DESIRED_STATES.stopped,
  ],
  [WORKSPACE_STATES.failed]: [
    WORKSPACE_DESIRED_STATES.restarting,
    WORKSPACE_DESIRED_STATES.running,
  ],
};

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    actualState: {
      type: String,
      required: true,
    },
    desiredState: {
      type: String,
      required: true,
    },
  },
  computed: {
    isVisible() {
      return (
        ACTUAL_STATE_TO_DESIRED_STATE_VISIBILITY_MAP[this.actualState]?.includes(
          this.desiredState,
        ) || false
      );
    },
    isRestartingDesiredState() {
      return this.desiredState === WORKSPACE_DESIRED_STATES.restarting;
    },
    tooltip() {
      return this.isRestartingDesiredState
        ? i18n.restartingWorkspaceTooltip
        : i18n.restartWorkspaceTooltip;
    },
  },
};
</script>
<template>
  <span v-if="isVisible" v-gl-tooltip :title="tooltip">
    <gl-button
      :disabled="isRestartingDesiredState"
      :loading="isRestartingDesiredState"
      :aria-label="tooltip"
      icon="retry"
      @click="$emit('click')"
    />
  </span>
</template>
