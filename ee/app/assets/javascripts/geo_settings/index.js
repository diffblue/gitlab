import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GeoSettingsApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  // This file is set up to provide multi-version support in case the Rails bundle doesn't update.
  // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113771#note_1306337644
  // Duplication to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/396730

  const el = document.getElementById('js-geo-settings-form');

  const {
    dataset: { nodesPath, sitesPath },
  } = el;

  return new Vue({
    el,
    store: createStore(sitesPath || nodesPath),
    components: {
      GeoSettingsApp,
    },

    render(createElement) {
      return createElement('geo-settings-app');
    },
  });
};
