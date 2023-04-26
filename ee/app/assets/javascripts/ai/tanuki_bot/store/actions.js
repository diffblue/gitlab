import Api from 'ee/api';
import * as types from './mutation_types';

export const sendMessage = async ({ commit }, msg) => {
  try {
    commit(types.SET_LOADING, true);
    commit(types.ADD_USER_MESSAGE, msg);

    const { data } = await Api.requestTanukiBotResponse(msg);

    commit(types.ADD_TANUKI_MESSAGE, data);
  } catch {
    commit(types.ADD_ERROR_MESSAGE);
  } finally {
    commit(types.SET_LOADING, false);
  }
};
