import { flatten } from 'lodash';
import Api from 'ee/api';
import { createAlert } from '~/alert';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import * as types from './mutation_types';

const i18n = {
  errors: s__('Geo|Errors:'),
  errorFetchingGroups: s__("Geo|There was an error fetching the Sites's Groups"),
  errorFetchingSite: s__('Geo|There was an error saving this Geo Site'),
};

const getSaveErrorMessageParts = (messages) => {
  return flatten(
    Object.entries(messages || {}).map(([key, value]) => value.map((x) => `${key} ${x}`)),
  );
};

const getSaveErrorMessage = (messages) => {
  const parts = getSaveErrorMessageParts(messages);
  return `${i18n.errors} ${parts.join(', ')}`;
};

export const requestSyncNamespaces = ({ commit }) => commit(types.REQUEST_SYNC_NAMESPACES);
export const receiveSyncNamespacesSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_SYNC_NAMESPACES_SUCCESS, data);
export const receiveSyncNamespacesError = ({ commit }) => {
  createAlert({
    message: i18n.errorFetchingGroups,
  });
  commit(types.RECEIVE_SYNC_NAMESPACES_ERROR);
};

export const fetchSyncNamespaces = ({ dispatch }, search) => {
  dispatch('requestSyncNamespaces');

  Api.groups(search)
    .then((res) => {
      dispatch('receiveSyncNamespacesSuccess', res);
    })
    .catch(() => {
      dispatch('receiveSyncNamespacesError');
    });
};

export const requestSaveGeoSite = ({ commit }) => commit(types.REQUEST_SAVE_GEO_SITE);
export const receiveSaveGeoSiteSuccess = ({ commit, state }) => {
  commit(types.RECEIVE_SAVE_GEO_SITE_COMPLETE);
  visitUrl(state.sitesPath);
};
export const receiveSaveGeoSiteError = ({ commit }, data) => {
  let errorMessage = i18n.errorFetchingSite;

  if (data?.message) {
    errorMessage += ` ${getSaveErrorMessage(data.message)}`;
  }

  createAlert({
    message: errorMessage,
  });
  commit(types.RECEIVE_SAVE_GEO_SITE_COMPLETE);
};

export const saveGeoSite = ({ dispatch }, site) => {
  dispatch('requestSaveGeoSite');
  const sanitizedSite = convertObjectPropsToSnakeCase(site);
  const saveFunc = site.id ? 'updateGeoSite' : 'createGeoSite';

  Api[saveFunc](sanitizedSite)
    .then(() => dispatch('receiveSaveGeoSiteSuccess'))
    .catch(({ response }) => {
      dispatch('receiveSaveGeoSiteError', response.data);
    });
};

export const setError = ({ commit }, { key, error }) => commit(types.SET_ERROR, { key, error });
