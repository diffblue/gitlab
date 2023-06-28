import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DashboardsApp from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-analytics-dashboards-app');
  const { fullPath, namespaces, pointerProject } = el.dataset;

  let queryPaths;
  try {
    queryPaths = JSON.parse(namespaces).map((namespace) => namespace.full_path);
  } catch {
    queryPaths = [];
  }

  let yamlConfigProject;
  try {
    yamlConfigProject = convertObjectPropsToCamelCase(JSON.parse(pointerProject));
  } catch (e) {
    yamlConfigProject = undefined;
  }

  return new Vue({
    el,
    name: 'DashboardsApp',
    apolloProvider,
    render: (createElement) =>
      createElement(DashboardsApp, {
        props: {
          fullPath,
          queryPaths,
          yamlConfigProject,
        },
      }),
  });
};
