import * as types from './mutation_types';

export const setStoreGroupName = ({ commit }, groupName) =>
  commit(types.SET_STORE_GROUP_NAME, groupName);

export const setStoreGroupPath = ({ commit }, groupPath) =>
  commit(types.SET_STORE_GROUP_PATH, groupPath);
