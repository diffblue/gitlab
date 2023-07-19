<script>
import { GlLoadingIcon } from '@gitlab/ui';
import CeWebIdeLink from '~/vue_shared/components/web_ide_link.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WorkspacesDropdownGroup from 'ee_component/remote_development/components/workspaces_dropdown_group/workspaces_dropdown_group.vue';
import GetProjectDetailsQuery from 'ee_component/remote_development/components/common/get_project_details_query.vue';

export default {
  components: {
    GlLoadingIcon,
    WorkspacesDropdownGroup,
    GetProjectDetailsQuery,
    CeWebIdeLink,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    newWorkspacePath: {
      default: '',
    },
  },
  props: {
    ...CeWebIdeLink.props,
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
      isDropdownVisible: false,
      projectDetailsLoaded: false,
      supportsWorkspaces: false,
    };
  },
  computed: {
    isWorkspacesDropdownGroupAvailable() {
      return this.glFeatures.remoteDevelopment && this.glFeatures.remoteDevelopmentFeatureFlag;
    },
    shouldRenderWorkspacesDropdownGroup() {
      return this.isWorkspacesDropdownGroupAvailable && this.isDropdownVisible;
    },
    shouldRenderWorkspacesDropdownGroupBeforeActions() {
      return (
        this.shouldRenderWorkspacesDropdownGroup &&
        (!this.projectDetailsLoaded || this.supportsWorkspaces)
      );
    },
    shouldRenderWorkspacesDropdownGroupAfterActions() {
      return (
        this.shouldRenderWorkspacesDropdownGroup &&
        this.projectDetailsLoaded &&
        !this.supportsWorkspaces
      );
    },
  },
  methods: {
    onDropdownShown() {
      this.isDropdownVisible = true;
    },
    onDropdownHidden() {
      this.isDropdownVisible = false;
    },
    onProjectDetailsResult({ hasDevFile, clusterAgents }) {
      this.projectDetailsLoaded = true;
      this.supportsWorkspaces = hasDevFile && clusterAgents.length > 0;
    },
    onProjectDetailsError() {
      this.projectDetailsLoaded = true;
    },
  },
};
</script>

<template>
  <ce-web-ide-link
    v-bind="$props"
    @edit="$emit('edit', $event)"
    @shown="onDropdownShown"
    @hidden="onDropdownHidden"
  >
    <template v-if="shouldRenderWorkspacesDropdownGroupBeforeActions" #before-actions>
      <get-project-details-query
        :project-full-path="projectPath"
        @result="onProjectDetailsResult"
        @error="onProjectDetailsError"
      />
      <workspaces-dropdown-group
        v-if="projectDetailsLoaded"
        :new-workspace-path="newWorkspacePath"
        :project-id="projectId"
        :project-full-path="projectPath"
        :supports-workspaces="supportsWorkspaces"
        border-position="bottom"
      />
      <div v-else class="gl-my-3">
        <gl-loading-icon />
      </div>
    </template>
    <template v-if="shouldRenderWorkspacesDropdownGroupAfterActions" #after-actions>
      <workspaces-dropdown-group
        :new-workspace-path="newWorkspacePath"
        :project-id="projectId"
        :project-full-path="projectPath"
        :supports-workspaces="supportsWorkspaces"
        border-position="top"
      />
    </template>
  </ce-web-ide-link>
</template>
