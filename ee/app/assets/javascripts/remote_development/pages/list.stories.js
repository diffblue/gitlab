import Vue from 'vue';
import VueApollo from 'vue-apollo';
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
};

export const Default = Template.bind({});

Default.args = {};
