<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import WorkspaceStateIndicator from '../common/workspace_state_indicator.vue';

export default {
  components: {
    GlDisclosureDropdownItem,
    WorkspaceStateIndicator,
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
  <gl-disclosure-dropdown-item :item="dropdownItem" class="gl-display-flex gl-align-items-center">
    <template #list-item>
      <workspace-state-indicator class="gl-mr-2" :workspace-state="workspace.actualState" />
      <span class="gl-mr-4">{{ workspace.name }}</span>
    </template>
  </gl-disclosure-dropdown-item>
</template>
