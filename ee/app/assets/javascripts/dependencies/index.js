import Vue from 'vue';
import DependenciesApp from './components/app.vue';
import createStore from './store';

export default () => {
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
    provide: {
      emptyStateSvgPath,
      documentationPath,
      endpoint,
      exportEndpoint,
      supportDocumentationPath,
    },
    render(createElement) {
      return createElement(DependenciesApp);
    },
  });
};
