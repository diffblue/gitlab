import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DashboardsApp from './components/app.vue';

const buildNamespaces = ({ groupFullPath, groupName, jsonString = '' }) => {
  const namespaces = jsonString ? JSON.parse(jsonString).map(convertObjectPropsToCamelCase) : [];
  return [
    {
      name: groupName,
      fullPath: groupFullPath,
      isProject: false,
    },
  ].concat(namespaces);
};

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-analytics-dashboards-app');
  const { groupFullPath, groupName, namespaces, pointerProject: pointerProjectJson } = el.dataset;

  const chartConfigs = buildNamespaces({ groupFullPath, groupName, jsonString: namespaces });
  let pointerProject;
  try {
    pointerProject = JSON.parse(pointerProjectJson);
  } catch {
    pointerProject = undefined;
  }

  return new Vue({
    el,
    name: 'DashboardsApp',
    apolloProvider,
    render: (createElement) =>
      createElement(DashboardsApp, {
        props: { chartConfigs, pointerProject },
      }),
  });
};
