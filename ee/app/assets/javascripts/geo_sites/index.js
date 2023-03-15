import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import Translate from '~/vue_shared/translate';
import GeoSitesApp from './components/app.vue';
import createStore from './store';

Vue.use(Translate);

export const initGeoSites = () => {
  // This file is set up to provide multi-version support in case the Rails bundle doesn't update.
  // See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113771#note_1306337644
  const el = document.getElementById('js-geo-sites') || document.getElementById('js-geo-nodes');

  if (!el) {
    return false;
  }

  const { newSiteUrl, geoSitesEmptyStateSvg } = el.dataset;
  const { newNodeUrl, geoNodesEmptyStateSvg } = el.dataset;
  const searchFilter = getParameterByName('search') || '';
  let { replicableTypes } = el.dataset;

  replicableTypes = convertObjectPropsToCamelCase(JSON.parse(replicableTypes), { deep: true });

  return new Vue({
    el,
    store: createStore({ replicableTypes, searchFilter }),
    provide: {
      geoSitesEmptyStateSvg: geoSitesEmptyStateSvg || geoNodesEmptyStateSvg,
    },
    render(createElement) {
      return createElement(GeoSitesApp, {
        props: {
          newSiteUrl: newSiteUrl || newNodeUrl,
        },
      });
    },
  });
};
