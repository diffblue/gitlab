import * as types from './mutation_types';

export default {
  [types.SET_STORE_GROUP_NAME](state, groupName) {
    state.storeGroupName = groupName;
  },
  [types.SET_STORE_GROUP_PATH](state, groupPath) {
    state.storeGroupPath = groupPath;
  },
};
