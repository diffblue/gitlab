import { MESSAGE_TYPES } from '../constants';
import { GENIE_CHAT_RESET_MESSAGE } from '../../constants';
import * as types from './mutation_types';

export const sendUserMessage = ({ commit }, msg) => {
  commit(types.SET_LOADING, true);
  commit(types.ADD_USER_MESSAGE, msg);
};

export const receiveMutationResponse = ({ commit }, { data, message }) => {
  const hasErrors = data?.aiAction?.errors?.length > 0;

  if (hasErrors) {
    commit(types.SET_LOADING, false);
    commit(types.ADD_ERROR_MESSAGE);
  } else if (message === GENIE_CHAT_RESET_MESSAGE) {
    commit(types.SET_LOADING, false);
  }
};

export const receiveTanukiBotMessage = ({ commit, dispatch }, data) => {
  const response = data.aiCompletionResponse?.responseBody;
  const errors = data.aiCompletionResponse?.errors;

  if (errors?.length) {
    dispatch('tanukiBotMessageError');
  } else if (response) {
    commit(types.SET_LOADING, false);

    let parsedResponse;
    try {
      parsedResponse = JSON.parse(response);
    } catch {
      parsedResponse = { content: response };
    }
    commit(types.ADD_TANUKI_MESSAGE, parsedResponse);
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
    if (msg.errors?.length) {
      commit(types.ADD_ERROR_MESSAGE);
    } else {
      switch (msg.role.toLowerCase()) {
        case MESSAGE_TYPES.USER:
          commit(types.ADD_USER_MESSAGE, msg.content);
          break;
        case MESSAGE_TYPES.TANUKI:
          try {
            parsedProps = JSON.parse(msg.content);
          } catch {
            parsedProps = msg;
          }
          commit(types.ADD_TANUKI_MESSAGE, parsedProps);
          break;
        default:
          break;
      }
    }
  });
};
