import * as types from './mutation_types';

export const sendUserMessage = ({ commit }, msg) => {
  commit(types.SET_LOADING, true);
  commit(types.ADD_USER_MESSAGE, msg);
};

export const receiveTanukiBotMessage = ({ commit, dispatch }, data) => {
  const response = data.aiCompletionResponse?.responseBody;
  const errors = data.aiCompletionResponse?.errors;

  if (errors?.length) {
    dispatch('tanukiBotMessageError');
  } else if (response) {
    commit(types.SET_LOADING, false);
    commit(types.ADD_TANUKI_MESSAGE, JSON.parse(response));
  }
};

export const tanukiBotMessageError = ({ commit }) => {
  commit(types.SET_LOADING, false);
  commit(types.ADD_ERROR_MESSAGE);
};
