<script>
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';

export default {
  components: {
    WorkspacesDropdownGroup: () =>
      import(
        'ee_component/remote_development/components/workspaces_dropdown_group/workspaces_dropdown_group.vue'
      ),
    WebIdeLink,
  },
  inject: {
    newWorkspacePath: {
      default: '',
    },
  },
  props: {
    ...WebIdeLink.props,
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    projectId: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      isWorkspacesDropdownGroupEnabled: false,
    };
  },
  methods: {
    disableWorkspacesDropdownGroup() {
      this.isWorkspacesDropdownGroupEnabled = false;
    },
    enableWorkspacesDropdownGroup() {
      this.isWorkspacesDropdownGroupEnabled = true;
    },
  },
};
</script>

<template>
  <web-ide-link
    v-bind="$props"
    @edit="$emit('edit', $event)"
    @shown="enableWorkspacesDropdownGroup"
    @hidden="disableWorkspacesDropdownGroup"
  >
    <template #after-actions>
      <workspaces-dropdown-group
        v-if="isWorkspacesDropdownGroupEnabled"
        :new-workspace-path="newWorkspacePath"
        :project-id="projectId"
        :project-full-path="projectPath"
      />
    </template>
  </web-ide-link>
</template>
