import { createAlert } from '~/alert';
import { s__, __, sprintf } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { PREV, NEXT, DEFAULT_PAGE_SIZE } from '../constants';
import buildReplicableTypeQuery from '../graphql/replicable_type_query_builder';
import replicableTypeUpdateMutation from '../graphql/replicable_type_update_mutation.graphql';
import replicableTypeBulkUpdateMutation from '../graphql/replicable_type_bulk_update_mutation.graphql';
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

  const replicationState = state.statusFilter ? state.statusFilter.toUpperCase() : null;

  const client = getGraphqlClient(state.geoCurrentSiteId, state.geoTargetSiteId);

  client
    .query({
      query: buildReplicableTypeQuery(state.graphqlFieldName, state.verificationEnabled),
      variables: { first, last, before, after, replicationState },
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

// Initiate All Replicable Action
export const requestInitiateAllReplicableAction = ({ commit }) =>
  commit(types.REQUEST_INITIATE_ALL_REPLICABLE_ACTION);
export const receiveInitiateAllReplicableActionSuccess = (
  { getters, commit, dispatch },
  { action },
) => {
  toast(
    sprintf(s__('Geo|All %{replicableType} are being scheduled for %{action}'), {
      replicableType: getters.replicableTypeName,
      action: action.replace('_', ' '),
    }),
  );
  commit(types.RECEIVE_INITIATE_ALL_REPLICABLE_ACTION_SUCCESS);
  dispatch('fetchReplicableItems');
};
export const receiveInitiateAllReplicableActionError = ({ getters, commit }, { action }) => {
  createAlert({
    message: sprintf(
      s__('Geo|There was an error scheduling action %{action} for %{replicableType}'),
      {
        replicableType: getters.replicableTypeName,
        action: action.replace('_', ' '),
      },
    ),
  });
  commit(types.RECEIVE_INITIATE_ALL_REPLICABLE_ACTION_ERROR);
};

export const initiateAllReplicableAction = ({ state, dispatch }, { action }) => {
  dispatch('requestInitiateAllReplicableAction');

  const client = getGraphqlClient(state.geoCurrentSiteId, state.geoTargetSiteId);

  client
    .mutate({
      mutation: replicableTypeBulkUpdateMutation,
      variables: {
        action: action.toUpperCase(),
        registryClass: state.graphqlMutationRegistryClass,
      },
    })
    .then(() => dispatch('receiveInitiateAllReplicableActionSuccess', { action }))
    .catch(() => {
      dispatch('receiveInitiateAllReplicableActionError', { action });
    });
};

// Initiate Replicable Action
export const requestInitiateReplicableAction = ({ commit }) =>
  commit(types.REQUEST_INITIATE_REPLICABLE_ACTION);
export const receiveInitiateReplicableActionSuccess = ({ commit, dispatch }, { name, action }) => {
  toast(sprintf(__('%{name} is scheduled for %{action}'), { name, action }));
  commit(types.RECEIVE_INITIATE_REPLICABLE_ACTION_SUCCESS);
  dispatch('fetchReplicableItems');
};
export const receiveInitiateReplicableActionError = ({ commit }, { name }) => {
  createAlert({
    message: sprintf(__('There was an error syncing project %{name}'), { name }),
  });
  commit(types.RECEIVE_INITIATE_REPLICABLE_ACTION_ERROR);
};

export const initiateReplicableAction = ({ state, dispatch }, { registryId, name, action }) => {
  dispatch('requestInitiateReplicableAction');

  const client = getGraphqlClient(state.geoCurrentSiteId, state.geoTargetSiteId);

  client
    .mutate({
      mutation: replicableTypeUpdateMutation,
      variables: {
        action: action.toUpperCase(),
        registryId,
        registryClass: state.graphqlMutationRegistryClass,
      },
    })
    .then(() => dispatch('receiveInitiateReplicableActionSuccess', { name, action }))
    .catch(() => {
      dispatch('receiveInitiateReplicableActionError', { name });
    });
};

// Filtering/Pagination
export const setStatusFilter = ({ commit }, filter) => {
  commit(types.SET_STATUS_FILTER, filter);
};

export const setSearch = ({ commit }, search) => {
  commit(types.SET_SEARCH, search);
};
