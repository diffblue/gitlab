import Vue from 'vue';
import DependenciesApp from './components/app.vue';
import createStore from './store';
import apolloProvider from './graphql/provider';

export default (namespaceType) => {
  const el = document.querySelector('#js-dependencies-app');

  const {
    emptyStateSvgPath,
    documentationPath,
    endpoint,
    exportEndpoint,
    supportDocumentationPath,
  } = el.dataset;

  const store = createStore();

  return new Vue({
    el,
    name: 'DependenciesAppRoot',
    components: {
      DependenciesApp,
    },
    store,
    apolloProvider,
    provide: {
      emptyStateSvgPath,
      documentationPath,
      endpoint,
      exportEndpoint,
      supportDocumentationPath,
      namespaceType,
    },
    render(createElement) {
      return createElement(DependenciesApp);
    },
  });
};
