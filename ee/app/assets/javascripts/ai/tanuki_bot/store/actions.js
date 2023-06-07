import { MESSAGE_TYPES } from '../constants';
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

export const setMessages = ({ commit }, messages) => {
  if (messages[messages.length - 1].role.toLowerCase() !== MESSAGE_TYPES.USER) {
    // the last messages is from user, hence the response from AI is in flight
    commit(types.SET_LOADING, false);
  }
  messages.forEach((msg) => {
    let parsedProps;
    switch (msg.role.toLowerCase()) {
      case MESSAGE_TYPES.USER:
        commit(types.ADD_USER_MESSAGE, msg.content);
        break;
      case MESSAGE_TYPES.TANUKI:
        try {
          parsedProps = JSON.parse(msg.content);
        } catch {
          parsedProps = msg.content;
        }
        commit(types.ADD_TANUKI_MESSAGE, parsedProps);
        break;
      default:
        break;
    }
  });
};
