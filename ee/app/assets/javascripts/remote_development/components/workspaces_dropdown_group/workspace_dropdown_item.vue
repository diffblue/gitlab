<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import WorkspaceStateIndicator from '../common/workspace_state_indicator.vue';
import WorkspaceActions from '../common/workspace_actions.vue';

export default {
  components: {
    GlDisclosureDropdownItem,
    WorkspaceStateIndicator,
    WorkspaceActions,
  },
  props: {
    workspace: {
      type: Object,
      required: true,
    },
  },
  computed: {
    dropdownItem() {
      return {
        href: this.workspace.url,
        text: this.workspace.name,
      };
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item class="gl-my-0" :item="dropdownItem">
    <template #list-item>
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <span class="gl-display-inline-flex gl-align-items-center">
          <workspace-state-indicator class="gl-mr-3" :workspace-state="workspace.actualState" />
          <span class="gl-mr-4 gl-text-truncate">{{ workspace.name }}</span>
        </span>
        <workspace-actions
          :actual-state="workspace.actualState"
          :desired-state="workspace.desiredState"
          compact
          @click="$emit('updateWorkspace', { desiredState: $event })"
        />
      </div>
    </template>
  </gl-disclosure-dropdown-item>
</template>
