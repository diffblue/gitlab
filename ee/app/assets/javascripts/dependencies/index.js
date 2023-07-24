import Vue from 'vue';
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
  } = el.dataset;

  const store = createStore();

  const provide = {
    emptyStateSvgPath,
    documentationPath,
    endpoint,
    exportEndpoint,
    supportDocumentationPath,
    namespaceType,
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
