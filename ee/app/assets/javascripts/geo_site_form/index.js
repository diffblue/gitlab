import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import Translate from '~/vue_shared/translate';
import GeoSiteFormApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-geo-site-form');

  const {
    dataset: { selectiveSyncTypes, syncShardsOptions, siteData, sitesPath },
  } = el;

  return new Vue({
    el,
    store: createStore(sitesPath),
    render(createElement) {
      let site;
      if (siteData) {
        site = JSON.parse(siteData);
        site = convertObjectPropsToCamelCase(site, { deep: true });
      }

      return createElement(GeoSiteFormApp, {
        props: {
          selectiveSyncTypes: JSON.parse(selectiveSyncTypes),
          syncShardsOptions: JSON.parse(syncShardsOptions),
          site,
        },
      });
    },
  });
};
