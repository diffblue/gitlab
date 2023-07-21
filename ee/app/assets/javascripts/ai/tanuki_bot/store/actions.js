import { MESSAGE_TYPES } from '../constants';
import { GENIE_CHAT_RESET_MESSAGE } from '../../constants';
import * as types from './mutation_types';

export const sendUserMessage = async ({ commit }, msg) => {
  commit(types.SET_LOADING, true);
  commit(types.ADD_USER_MESSAGE, msg);
};

export const receiveMutationResponse = ({ commit, dispatch }, { data, message }) => {
  const hasErrors = data?.aiAction?.errors?.length > 0;

  if (hasErrors) {
    dispatch('tanukiBotMessageError');
  } else if (message === GENIE_CHAT_RESET_MESSAGE) {
    commit(types.SET_LOADING, false);
  }
};

export const receiveTanukiBotMessage = async ({ commit, dispatch }, data) => {
  const { errors = [], responseBody } = data.aiCompletionResponse || {};

  let parsedResponse;
  try {
    parsedResponse = JSON.parse(responseBody);
  } catch {
    parsedResponse = { content: responseBody };
  }

  if (errors?.length) {
    dispatch('tanukiBotMessageError', parsedResponse);
  } else if (responseBody) {
    commit(types.SET_LOADING, false);

    commit(types.ADD_TANUKI_MESSAGE, parsedResponse);
  }
};

export const tanukiBotMessageError = ({ commit }, data) => {
  commit(types.SET_LOADING, false);
  commit(types.ADD_ERROR_MESSAGE, data);
};

export const setMessages = ({ commit, dispatch }, messages) => {
  messages.forEach((msg) => {
    if (msg.errors?.length) {
      dispatch('tanukiBotMessageError', msg);
    } else {
      switch (msg.role.toLowerCase()) {
        case MESSAGE_TYPES.USER:
          dispatch('sendUserMessage', msg.content);
          commit(types.SET_LOADING, false);
          break;
        case MESSAGE_TYPES.TANUKI:
          dispatch('receiveTanukiBotMessage', {
            aiCompletionResponse: { responseBody: msg.content },
          });
          break;
        default:
          break;
      }
    }
  });
};
