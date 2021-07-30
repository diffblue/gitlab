import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GeoSettingsApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-geo-settings-form');

  const {
    dataset: { nodesPath },
  } = el;

  return new Vue({
    el,
    store: createStore(nodesPath),
    components: {
      GeoSettingsApp,
    },

    render(createElement) {
      return createElement('geo-settings-app');
    },
  });
};
