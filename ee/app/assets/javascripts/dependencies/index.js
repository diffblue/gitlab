import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import DependenciesApp from './components/app.vue';
import createStore from './store';
import apolloProvider from './graphql/provider';
import { NAMESPACE_GROUP } from './constants';

export default (namespaceType) => {
  const el = document.querySelector('#js-dependencies-app');

  const {
    emptyStateSvgPath,
    documentationPath,
    endpoint,
    exportEndpoint,
    supportDocumentationPath,
    locationsEndpoint,
    enableProjectSearch,
  } = el.dataset;

  const store = createStore();

  const provide = {
    emptyStateSvgPath,
    documentationPath,
    endpoint,
    exportEndpoint,
    supportDocumentationPath,
    namespaceType,
    enableProjectSearch: parseBoolean(enableProjectSearch),
  };

  if (namespaceType === NAMESPACE_GROUP) {
    provide.locationsEndpoint = locationsEndpoint;
  }

  return new Vue({
    el,
    name: 'DependenciesAppRoot',
    components: {
      DependenciesApp,
    },
    store,
    apolloProvider,
    provide,
    render(createElement) {
      return createElement(DependenciesApp);
    },
  });
};
