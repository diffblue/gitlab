import Vue from 'vue';
import DependenciesApp from './components/app.vue';
import createStore from './store';

export default () => {
  const el = document.querySelector('#js-dependencies-app');

  const provide = {
    sbomSurveySvgPath: el.dataset.sbomSurveySvgPath,
    emptyStateSvgPath: el.dataset.emptyStateSvgPath,
    documentationPath: el.dataset.documentationPath,
    endpoint: el.dataset.endpoint,
    supportDocumentationPath: el.dataset.supportDocumentationPath,
  };

  const store = createStore();

  return new Vue({
    el,
    components: {
      DependenciesApp,
    },
    store,
    provide,
    render(createElement) {
      return createElement(DependenciesApp);
    },
  });
};
