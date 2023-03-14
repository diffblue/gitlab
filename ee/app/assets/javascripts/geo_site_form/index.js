import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import GeoSiteFormApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  // This file is set up to provide multi-version support in case the Rails bundle doesn't update.
  // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113771#note_1306337644
  const el =
    document.getElementById('js-geo-site-form') || document.getElementById('js-geo-node-form');

  const {
    dataset: { selectiveSyncTypes, syncShardsOptions, siteData, sitesPath },
  } = el;

  const {
    dataset: { nodeData, nodesPath },
  } = el;

  return new Vue({
    el,
    store: createStore(sitesPath || nodesPath),
    components: {
      GeoSiteFormApp,
    },
    render(createElement) {
      let site;
      if (siteData) {
        site = JSON.parse(siteData);
        site = convertObjectPropsToCamelCase(site, { deep: true });
      } else if (nodeData) {
        site = JSON.parse(nodeData);
        site = convertObjectPropsToCamelCase(site, { deep: true });
      }

      return createElement('geo-site-form-app', {
        props: {
          selectiveSyncTypes: JSON.parse(selectiveSyncTypes),
          syncShardsOptions: JSON.parse(syncShardsOptions),
          site,
        },
      });
    },
  });
};
