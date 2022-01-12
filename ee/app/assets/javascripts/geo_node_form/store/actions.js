import { flatten } from 'lodash';
import Api from 'ee/api';
import createFlash from '~/flash';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import * as types from './mutation_types';

const getSaveErrorMessageParts = (messages) => {
  return flatten(
    Object.entries(messages || {}).map(([key, value]) => value.map((x) => `${key} ${x}`)),
  );
};

const getSaveErrorMessage = (messages) => {
  const parts = getSaveErrorMessageParts(messages);
  return `${__('Errors:')} ${parts.join(', ')}`;
};

export const requestSyncNamespaces = ({ commit }) => commit(types.REQUEST_SYNC_NAMESPACES);
export const receiveSyncNamespacesSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_SYNC_NAMESPACES_SUCCESS, data);
export const receiveSyncNamespacesError = ({ commit }) => {
  createFlash({
    message: __("There was an error fetching the Sites's Groups"),
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

export const requestSaveGeoNode = ({ commit }) => commit(types.REQUEST_SAVE_GEO_NODE);
export const receiveSaveGeoNodeSuccess = ({ commit, state }) => {
  commit(types.RECEIVE_SAVE_GEO_NODE_COMPLETE);
  visitUrl(state.nodesPath);
};
export const receiveSaveGeoNodeError = ({ commit }, data) => {
  let errorMessage = __('There was an error saving this Geo Site');

  if (data?.message) {
    errorMessage += ` ${getSaveErrorMessage(data.message)}`;
  }

  createFlash({
    message: errorMessage,
  });
  commit(types.RECEIVE_SAVE_GEO_NODE_COMPLETE);
};

export const saveGeoNode = ({ dispatch }, node) => {
  dispatch('requestSaveGeoNode');
  const sanitizedNode = convertObjectPropsToSnakeCase(node);
  const saveFunc = node.id ? 'updateGeoNode' : 'createGeoNode';

  Api[saveFunc](sanitizedNode)
    .then(() => dispatch('receiveSaveGeoNodeSuccess'))
    .catch(({ response }) => {
      dispatch('receiveSaveGeoNodeError', response.data);
    });
};

export const setError = ({ commit }, { key, error }) => commit(types.SET_ERROR, { key, error });
