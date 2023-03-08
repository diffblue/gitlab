import Api from 'ee/api';
import { createAlert } from '~/alert';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const fetchSites = ({ commit }) => {
  commit(types.REQUEST_SITES);

  const promises = [Api.getGeoSites(), Api.getGeoSitesStatus()];

  Promise.all(promises)
    .then(([{ data: sites }, { data: statuses }]) => {
      const inflatedSites = sites.map((site) =>
        convertObjectPropsToCamelCase({
          ...site,
          // geo_node_id to be converted to geo_site_id in => https://gitlab.com/gitlab-org/gitlab/-/issues/369140
          ...statuses.find((status) => status.geo_node_id === site.id),
        }),
      );

      commit(types.RECEIVE_SITES_SUCCESS, inflatedSites);
    })
    .catch(() => {
      createAlert({ message: s__('Geo|There was an error fetching the Geo Sites') });
      commit(types.RECEIVE_SITES_ERROR);
    });
};

export const prepSiteRemoval = ({ commit }, id) => {
  commit(types.STAGE_SITE_REMOVAL, id);
};

export const cancelSiteRemoval = ({ commit }) => {
  commit(types.UNSTAGE_SITE_REMOVAL);
};

export const removeSite = ({ commit, state }) => {
  commit(types.REQUEST_SITE_REMOVAL);

  return Api.removeGeoSite(state.siteToBeRemoved)
    .then(() => {
      commit(types.RECEIVE_SITE_REMOVAL_SUCCESS);
    })
    .catch(() => {
      createAlert({ message: s__('Geo|There was an error deleting the Geo Site') });
      commit(types.RECEIVE_SITE_REMOVAL_ERROR);
    });
};

export const setStatusFilter = ({ commit }, status) => {
  commit(types.SET_STATUS_FILTER, status);
};

export const setSearchFilter = ({ commit }, search) => {
  commit(types.SET_SEARCH_FILTER, search);
};
