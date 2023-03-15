import Api from 'ee/api';
import { createAlert } from '~/alert';
import {
  parseIntPagination,
  normalizeHeaders,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import { __, sprintf } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { FILTER_STATES, PREV, NEXT, DEFAULT_PAGE_SIZE } from '../constants';
import buildReplicableTypeQuery from '../graphql/replicable_type_query_builder';
import { getGraphqlClient } from '../utils';
import * as types from './mutation_types';

// Fetch Replicable Items
export const requestReplicableItems = ({ commit }) => commit(types.REQUEST_REPLICABLE_ITEMS);
export const receiveReplicableItemsSuccess = ({ commit }, data) =>
  commit(types.RECEIVE_REPLICABLE_ITEMS_SUCCESS, data);
export const receiveReplicableItemsError = ({ state, commit }) => {
  createAlert({
    message: sprintf(__('There was an error fetching the %{replicableType}'), {
      replicableType: state.replicableType,
    }),
  });
  commit(types.RECEIVE_REPLICABLE_ITEMS_ERROR);
};

export const fetchReplicableItems = ({ state, dispatch }, direction) => {
  dispatch('requestReplicableItems');

  return state.useGraphQl
    ? dispatch('fetchReplicableItemsGraphQl', direction)
    : dispatch('fetchReplicableItemsRestful');
};

export const fetchReplicableItemsGraphQl = ({ state, dispatch }, direction) => {
  let before = '';
  let after = '';

  // If we are going backwards we want the last 20, otherwise get the first 20.
  let first = DEFAULT_PAGE_SIZE;
  let last = null;

  if (direction === PREV) {
    before = state.paginationData.startCursor;
    first = null;
    last = DEFAULT_PAGE_SIZE;
  } else if (direction === NEXT) {
    after = state.paginationData.endCursor;
  }

  const client = getGraphqlClient(state.geoCurrentSiteId, state.geoTargetSiteId);

  client
    .query({
      query: buildReplicableTypeQuery(state.graphqlFieldName, state.verificationEnabled),
      variables: { first, last, before, after },
    })
    .then((res) => {
      // Query.geoNode to be renamed to Query.geoSite => https://gitlab.com/gitlab-org/gitlab/-/issues/396739
      if (!res.data.geoNode || !(state.graphqlFieldName in res.data.geoNode)) {
        dispatch('receiveReplicableItemsSuccess', { data: [], pagination: null });
        return;
      }

      const registries = res.data.geoNode[state.graphqlFieldName];
      const data = registries.nodes;
      const pagination = {
        ...registries.pageInfo,
        page: state.paginationData.page,
      };

      dispatch('receiveReplicableItemsSuccess', { data, pagination });
    })
    .catch(() => {
      dispatch('receiveReplicableItemsError');
    });
};

export const fetchReplicableItemsRestful = ({ state, dispatch }) => {
  const { filterOptions, currentFilterIndex, searchFilter, paginationData } = state;

  const statusFilter = currentFilterIndex ? filterOptions[currentFilterIndex] : filterOptions[0];

  const query = {
    page: paginationData.page,
    search: searchFilter || null,
    sync_status: statusFilter.value === FILTER_STATES.ALL.value ? null : statusFilter.value,
  };

  Api.getGeoReplicableItems(state.replicableType, query)
    .then((res) => {
      const normalizedHeaders = normalizeHeaders(res.headers);
      const pagination = parseIntPagination(normalizedHeaders);
      const data = convertObjectPropsToCamelCase(res.data, { deep: true });

      dispatch('receiveReplicableItemsSuccess', { data, pagination });
    })
    .catch(() => {
      dispatch('receiveReplicableItemsError');
    });
};

// Initiate All Replicable Syncs
export const requestInitiateAllReplicableSyncs = ({ commit }) =>
  commit(types.REQUEST_INITIATE_ALL_REPLICABLE_SYNCS);
export const receiveInitiateAllReplicableSyncsSuccess = (
  { state, commit, dispatch },
  { action },
) => {
  toast(
    sprintf(__('All %{replicableType} are being scheduled for %{action}'), {
      replicableType: state.replicableType,
      action,
    }),
  );
  commit(types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_SUCCESS);
  dispatch('fetchReplicableItems');
};
export const receiveInitiateAllReplicableSyncsError = ({ state, commit }) => {
  createAlert({
    message: sprintf(__('There was an error syncing the %{replicableType}'), {
      replicableType: state.replicableType,
    }),
  });
  commit(types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_ERROR);
};

export const initiateAllReplicableSyncs = ({ state, dispatch }, action) => {
  dispatch('requestInitiateAllReplicableSyncs');

  Api.initiateAllGeoReplicableSyncs(state.replicableType, action)
    .then(() => dispatch('receiveInitiateAllReplicableSyncsSuccess', { action }))
    .catch(() => {
      dispatch('receiveInitiateAllReplicableSyncsError');
    });
};

// Initiate Replicable Sync
export const requestInitiateReplicableSync = ({ commit }) =>
  commit(types.REQUEST_INITIATE_REPLICABLE_SYNC);
export const receiveInitiateReplicableSyncSuccess = ({ commit, dispatch }, { name, action }) => {
  toast(sprintf(__('%{name} is scheduled for %{action}'), { name, action }));
  commit(types.RECEIVE_INITIATE_REPLICABLE_SYNC_SUCCESS);
  dispatch('fetchReplicableItems');
};
export const receiveInitiateReplicableSyncError = ({ commit }, { name }) => {
  createAlert({
    message: sprintf(__('There was an error syncing project %{name}'), { name }),
  });
  commit(types.RECEIVE_INITIATE_REPLICABLE_SYNC_ERROR);
};

export const initiateReplicableSync = ({ state, dispatch }, { projectId, name, action }) => {
  dispatch('requestInitiateReplicableSync');

  Api.initiateGeoReplicableSync(state.replicableType, { projectId, action })
    .then(() => dispatch('receiveInitiateReplicableSyncSuccess', { name, action }))
    .catch(() => {
      dispatch('receiveInitiateReplicableSyncError', { name });
    });
};

// Filtering/Pagination
export const setFilter = ({ commit }, filterIndex) => {
  commit(types.SET_FILTER, filterIndex);
};

export const setSearch = ({ commit }, search) => {
  commit(types.SET_SEARCH, search);
};

export const setPage = ({ commit }, page) => {
  commit(types.SET_PAGE, page);
};
