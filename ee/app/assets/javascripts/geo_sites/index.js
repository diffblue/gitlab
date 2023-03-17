import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import Translate from '~/vue_shared/translate';
import GeoSitesApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export const initGeoSites = () => {
  const el = document.getElementById('js-geo-sites');

  if (!el) {
    return false;
  }

  const { newSiteUrl, geoSitesEmptyStateSvg } = el.dataset;
  const searchFilter = getParameterByName('search') || '';
  let { replicableTypes } = el.dataset;

  replicableTypes = convertObjectPropsToCamelCase(JSON.parse(replicableTypes), { deep: true });

  return new Vue({
    el,
    store: createStore({ replicableTypes, searchFilter }),
    provide: {
      geoSitesEmptyStateSvg,
    },
    render(createElement) {
      return createElement(GeoSitesApp, {
        props: {
          newSiteUrl,
        },
      });
    },
  });
};
