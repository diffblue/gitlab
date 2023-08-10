import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown } from '@gitlab/ui';
import { withGitLabAPIAccess } from 'storybook_addons/gitlab_api_access';
import WorkspacesDropdownGroup from './workspaces_dropdown_group.vue';

Vue.use(VueApollo);

export default {
  component: WorkspacesDropdownGroup,
  title: 'ee/remote_development/workspaces_dropdown_group',
};

export const WithAPIAccess = (args, { argTypes, createVueApollo }) => {
  return {
    components: { WorkspacesDropdownGroup, GlDisclosureDropdown },
    apolloProvider: createVueApollo(),
    provide: {
      glFeatures: {
        remoteDevelopment: true,
        remoteDevelopmentFeatureFlag: true,
      },
    },
    props: Object.keys(argTypes),
    template: `<gl-disclosure-dropdown fluid-width toggle-text="Edit">
      <workspaces-dropdown-group supports-workspaces border-position="top" :new-workspace-path="newWorkspacePath" :project-id="projectId" :project-full-path="projectFullPath" />
    </gl-disclosure-dropdown>`,
  };
};

WithAPIAccess.decorators = [withGitLabAPIAccess];
WithAPIAccess.args = {
  projectId: 0,
  projectFullPath: '',
  newWorkspacePath: '/create',
};
