<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { WORKSPACE_STATES } from '../../constants';

export const i18n = {
  terminatingWorkspaceTooltip: s__('Workspaces|Terminating'),
  terminateWorkspaceTooltip: s__('Workspaces|Terminate'),
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
      return ![WORKSPACE_STATES.unknown, WORKSPACE_STATES.terminated].includes(this.actualState);
    },
    isTerminatedDesiredState() {
      return this.desiredState === WORKSPACE_STATES.terminated;
    },
    tooltip() {
      return this.isTerminatedDesiredState
        ? i18n.terminatingWorkspaceTooltip
        : i18n.terminateWorkspaceTooltip;
    },
    icon() {
      return this.isTerminatedDesiredState ? '' : 'remove';
    },
  },
};
</script>
<template>
  <span v-if="isVisible" v-gl-tooltip :title="tooltip">
    <gl-button
      :disabled="isTerminatedDesiredState"
      :loading="isTerminatedDesiredState"
      :icon="icon"
      :aria-label="tooltip"
      @click="$emit('click')"
    />
  </span>
</template>
