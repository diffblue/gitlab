<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { WORKSPACE_DESIRED_STATES, WORKSPACE_STATES } from '../../constants';

export const i18n = {
  startingWorkspaceTooltip: s__('Workspaces|Starting'),
  startWorkspaceTooltip: s__('Workspaces|Start'),
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
        [WORKSPACE_STATES.stopped, WORKSPACE_STATES.starting].includes(this.actualState) &&
        [WORKSPACE_DESIRED_STATES.running, WORKSPACE_DESIRED_STATES.stopped].includes(
          this.desiredState,
        )
      );
    },
    isRunningDesiredState() {
      return this.desiredState === WORKSPACE_DESIRED_STATES.running;
    },
    tooltip() {
      return this.isRunningDesiredState
        ? i18n.startingWorkspaceTooltip
        : i18n.startWorkspaceTooltip;
    },
  },
};
</script>
<template>
  <span v-if="isVisible" v-gl-tooltip :title="tooltip">
    <gl-button
      :disabled="isRunningDesiredState"
      :loading="isRunningDesiredState"
      :aria-label="tooltip"
      icon="play"
      @click="$emit('click')"
    />
  </span>
</template>
