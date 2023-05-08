<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  WORKSPACE_STATES,
  FILL_CLASS_GREEN,
  FILL_CLASS_ORANGE,
  FILL_CLASS_RED,
} from '../../constants';

export const i18n = {
  tooltips: {
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

const STATE_TO_ICON_MAP = {
  [WORKSPACE_STATES.creationRequested]: 'status-running',
  [WORKSPACE_STATES.starting]: 'status-running',
  [WORKSPACE_STATES.running]: 'status-active',
  [WORKSPACE_STATES.stopping]: 'status-running',
  [WORKSPACE_STATES.stopped]: 'status-stopped',
  [WORKSPACE_STATES.terminating]: 'status-running',
  [WORKSPACE_STATES.terminated]: 'status-cancelled',
  [WORKSPACE_STATES.failed]: 'status_warning',
  [WORKSPACE_STATES.error]: 'status_warning',
  [WORKSPACE_STATES.unknown]: 'status_warning',
};

const STATE_TO_CSS_CLASS_MAP = {
  [WORKSPACE_STATES.creationRequested]: FILL_CLASS_GREEN,
  [WORKSPACE_STATES.starting]: FILL_CLASS_GREEN,
  [WORKSPACE_STATES.running]: FILL_CLASS_GREEN,
  [WORKSPACE_STATES.failed]: FILL_CLASS_ORANGE,
  [WORKSPACE_STATES.error]: FILL_CLASS_ORANGE,
  [WORKSPACE_STATES.terminating]: FILL_CLASS_RED,
  [WORKSPACE_STATES.terminated]: FILL_CLASS_RED,
  [WORKSPACE_STATES.unknown]: FILL_CLASS_ORANGE,
};

export default {
  components: {
    GlIcon,
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
      return STATE_TO_ICON_MAP[this.workspaceState];
    },
    iconLabel() {
      return i18n.tooltips[this.workspaceState];
    },
    iconClass() {
      return STATE_TO_CSS_CLASS_MAP[this.workspaceState];
    },
  },
};
</script>
<template>
  <gl-icon
    v-gl-tooltip
    :name="iconName"
    :size="12"
    :title="iconLabel"
    :aria-label="iconLabel"
    class="workspace-state-indicator"
    :class="iconClass"
    data-testid="workspace-state-indicator"
  />
</template>
