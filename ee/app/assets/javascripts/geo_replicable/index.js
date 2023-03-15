import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import GeoReplicableApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  // This file is set up to provide multi-version support in case the Rails bundle doesn't update.
  // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113771#note_1306337644
  // Duplication to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/396730

  const el = document.getElementById('js-geo-replicable');
  const {
    replicableType,
    geoTroubleshootingLink,
    geoReplicableEmptySvgPath,
    graphqlFieldName,
    verificationEnabled,
    geoCurrentNodeId,
    geoTargetNodeId,
    geoCurrentSiteId,
    geoTargetSiteId,
  } = el.dataset;

  return new Vue({
    el,
    store: createStore({
      replicableType,
      graphqlFieldName,
      verificationEnabled,
      geoCurrentSiteId: geoCurrentSiteId || geoCurrentNodeId,
      geoTargetSiteId: geoTargetSiteId || geoTargetNodeId,
    }),
    components: {
      GeoReplicableApp,
    },

    render(createElement) {
      return createElement('geo-replicable-app', {
        props: {
          geoTroubleshootingLink,
          geoReplicableEmptySvgPath,
        },
      });
    },
  });
};
