import Vue from 'vue';
import DependenciesApp from './components/app.vue';
import createStore from './store';

export default () => {
  const el = document.querySelector('#js-dependencies-app');

  const {
    endpoint,
    emptyStateSvgPath,
    documentationPath,
    supportDocumentationPath,
    sbomSurveySvgPath,
  } = el.dataset;

  const store = createStore();

  return new Vue({
    el,
    components: {
      DependenciesApp,
    },
    store,
    render(createElement) {
      return createElement(DependenciesApp, {
        props: {
          endpoint,
          emptyStateSvgPath,
          documentationPath,
          supportDocumentationPath,
          sbomSurveySvgPath,
        },
      });
    },
  });
};
