<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import Tracking from '~/tracking';
import WorkspaceStateIndicator from '../common/workspace_state_indicator.vue';
import WorkspaceActions from '../common/workspace_actions.vue';

export default {
  components: {
    GlDisclosureDropdownItem,
    WorkspaceStateIndicator,
    WorkspaceActions,
  },
  mixins: [Tracking.mixin()],
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
  methods: {
    trackOpenWorkspace() {
      this.track('click_consolidated_edit', { label: 'workspace' });
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown-item class="gl-my-0" :item="dropdownItem" @action="trackOpenWorkspace">
    <template #list-item>
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <span class="gl-display-inline-flex gl-align-items-center">
          <workspace-state-indicator class="gl-mr-3" :workspace-state="workspace.actualState" />
          <span class="gl-mr-4 gl-word-break-word">{{ workspace.name }}</span>
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
