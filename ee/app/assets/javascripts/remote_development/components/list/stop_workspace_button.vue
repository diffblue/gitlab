<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { WORKSPACE_DESIRED_STATES, WORKSPACE_STATES } from '../../constants';

export const i18n = {
  stoppingWorkspaceTooltip: s__('Workspaces|Stopping'),
  stopWorkspaceTooltip: s__('Workspaces|Stop'),
};

const VISIBLE_WORKSPACE_STATES = [
  WORKSPACE_STATES.stopping,
  WORKSPACE_STATES.running,
  WORKSPACE_STATES.failed,
];
const VISIBLE_WORKSPACE_DESIRED_STATES = [
  WORKSPACE_DESIRED_STATES.running,
  WORKSPACE_DESIRED_STATES.stopped,
];

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
        VISIBLE_WORKSPACE_STATES.includes(this.actualState) &&
        VISIBLE_WORKSPACE_DESIRED_STATES.includes(this.desiredState)
      );
    },
    isStoppedDesiredState() {
      return this.desiredState === WORKSPACE_DESIRED_STATES.stopped;
    },
    tooltip() {
      return this.isStoppedDesiredState ? i18n.stoppingWorkspaceTooltip : i18n.stopWorkspaceTooltip;
    },
  },
};
</script>
<template>
  <span v-if="isVisible" v-gl-tooltip :title="tooltip">
    <gl-button
      :disabled="isStoppedDesiredState"
      :loading="isStoppedDesiredState"
      :aria-label="tooltip"
      icon="stop"
      @click="$emit('click')"
    />
  </span>
</template>
