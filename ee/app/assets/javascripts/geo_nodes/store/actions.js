import Api from 'ee/api';
import createFlash from '~/flash';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import * as types from './mutation_types';

export const fetchNodes = ({ commit }) => {
  commit(types.REQUEST_NODES);

  const promises = [Api.getGeoNodes(), Api.getGeoNodesStatus()];

  Promise.all(promises)
    .then(([{ data: nodes }, { data: statuses }]) => {
      const inflatedNodes = nodes.map((node) =>
        convertObjectPropsToCamelCase({
          ...node,
          ...statuses.find((status) => status.geo_node_id === node.id),
        }),
      );

      commit(types.RECEIVE_NODES_SUCCESS, inflatedNodes);
    })
    .catch(() => {
      createFlash({ message: s__('Geo|There was an error fetching the Geo Sites') });
      commit(types.RECEIVE_NODES_ERROR);
    });
};

export const prepNodeRemoval = ({ commit }, id) => {
  commit(types.STAGE_NODE_REMOVAL, id);
};

export const cancelNodeRemoval = ({ commit }) => {
  commit(types.UNSTAGE_NODE_REMOVAL);
};

export const removeNode = ({ commit, state }) => {
  commit(types.REQUEST_NODE_REMOVAL);

  return Api.removeGeoNode(state.nodeToBeRemoved)
    .then(() => {
      commit(types.RECEIVE_NODE_REMOVAL_SUCCESS);
    })
    .catch(() => {
      createFlash({ message: s__('Geo|There was an error deleting the Geo Site') });
      commit(types.RECEIVE_NODE_REMOVAL_ERROR);
    });
};

export const setStatusFilter = ({ commit }, status) => {
  commit(types.SET_STATUS_FILTER, status);
};
