import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GeoReplicableApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-geo-replicable');
  const {
    replicableType,
    geoReplicableEmptySvgPath,
    graphqlFieldName,
    verificationEnabled,
    geoCurrentSiteId,
    geoTargetSiteId,
  } = el.dataset;

  return new Vue({
    el,
    store: createStore({
      replicableType,
      graphqlFieldName,
      verificationEnabled,
      geoCurrentSiteId,
      geoTargetSiteId,
    }),

    render(createElement) {
      return createElement(GeoReplicableApp, {
        props: {
          geoReplicableEmptySvgPath,
        },
      });
    },
  });
};
