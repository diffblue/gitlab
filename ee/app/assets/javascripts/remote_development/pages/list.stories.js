import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { withGitLabAPIAccess } from 'storybook_addons/gitlab_api_access';
import WorkspacesList from './list.vue';

Vue.use(VueApollo);

const Template = (_, { argTypes, createVueApollo }) => {
  return {
    components: { WorkspacesList },
    apolloProvider: createVueApollo(),
    provide: {
      emptyStateSvgPath: '',
    },
    props: Object.keys(argTypes),
    template: '<workspaces-list />',
  };
};

export default {
  component: WorkspacesList,
  title: 'ee/remote_development/workspaces_list',
  decorators: [withGitLabAPIAccess],
};

export const Default = Template.bind({});

Default.args = {};
