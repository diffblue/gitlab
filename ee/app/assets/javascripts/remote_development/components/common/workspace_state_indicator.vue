<script>
import { GlTooltipDirective, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import { WORKSPACE_STATES } from '../../constants';

export const i18n = {
  labels: {
    [WORKSPACE_STATES.creationRequested]: s__('Workspaces|Creating'),
    [WORKSPACE_STATES.starting]: s__('Workspaces|Starting'),
    [WORKSPACE_STATES.running]: s__('Workspaces|Running'),
    [WORKSPACE_STATES.stopping]: s__('Workspaces|Stopping'),
    [WORKSPACE_STATES.stopped]: s__('Workspaces|Stopped'),
    [WORKSPACE_STATES.terminating]: s__('Workspaces|Terminating'),
    [WORKSPACE_STATES.terminated]: s__('Workspaces|Terminated'),
    [WORKSPACE_STATES.failed]: s__('Workspaces|Failed'),
    [WORKSPACE_STATES.error]: s__('Workspaces|Error'),
    [WORKSPACE_STATES.unknown]: s__('Workspaces|Unknown state'),
  },
};

const stateLabel = [
  WORKSPACE_STATES.creationRequested,
  WORKSPACE_STATES.starting,
  WORKSPACE_STATES.stopping,
  WORKSPACE_STATES.terminating,
];

const STATE_TO_VARIANT = {
  [WORKSPACE_STATES.creationRequested]: 'success',
  [WORKSPACE_STATES.starting]: 'success',
  [WORKSPACE_STATES.running]: 'success',
  [WORKSPACE_STATES.failed]: 'danger',
  [WORKSPACE_STATES.error]: 'danger',
  [WORKSPACE_STATES.stopping]: 'info',
  [WORKSPACE_STATES.stopped]: 'info',
  [WORKSPACE_STATES.terminating]: 'muted',
  [WORKSPACE_STATES.terminated]: 'muted',
  [WORKSPACE_STATES.unknown]: 'danger',
};

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    workspaceState: {
      type: String,
      required: true,
      validator: (value) => Object.values(WORKSPACE_STATES).includes(value),
    },
  },
  computed: {
    iconName() {
      return stateLabel.includes(this.workspaceState) ? 'status' : '';
    },
    iconLabel() {
      return i18n.labels[this.workspaceState];
    },
    variant() {
      return STATE_TO_VARIANT[this.workspaceState];
    },
  },
};
</script>
<template>
  <gl-badge
    :icon="iconName"
    class="workspace-state-indicator"
    :variant="variant"
    data-testid="workspace-state-indicator"
    :data-qa-title="iconLabel"
    >{{ iconLabel }}</gl-badge
  >
</template>
