import Vue from 'vue';
import EpicFilteredSearch from 'ee_component/boards/components/epic_filtered_search.vue';
import store from '~/boards/stores';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';

export default (apolloProvider) => {
  const el = document.getElementById('js-board-filtered-search');
  const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });
  const initialFilterParams = {
    ...convertObjectPropsToCamelCase(rawFilterParams, {}),
  };

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'EpicBoardFilteredSearchRoot',
    provide: {
      initialFilterParams,
    },
    store, // TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/324094
    apolloProvider,
    render: (createElement) =>
      createElement(EpicFilteredSearch, {
        props: { fullPath: store.state?.fullPath || '', boardType: store.state?.boardType || '' },
      }),
  });
};
