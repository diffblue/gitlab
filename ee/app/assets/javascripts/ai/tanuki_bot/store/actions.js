import { GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';
import * as types from './mutation_types';

const proxyMessageContent = (message, propsToUpdate) => {
  const mutatedMessage = { ...message };
  delete mutatedMessage.responseBody;

  return {
    ...mutatedMessage,
    ...propsToUpdate,
    role: mutatedMessage.role || GENIE_CHAT_MODEL_ROLES.user,
  };
};

export const addDuoChatMessage = async ({ commit }, messageData = { content: '' }) => {
  const { errors = [], responseBody = '', content = '' } = messageData || {};
  const msgContent = content || responseBody || errors.join('; ');

  if (msgContent) {
    let parsedResponse;
    try {
      parsedResponse = JSON.parse(msgContent);
    } catch {
      parsedResponse = { content: msgContent };
    }
    const message = proxyMessageContent(messageData, parsedResponse);
    if (message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.tool) {
      commit(types.ADD_TOOL_MESSAGE, message);
    } else {
      commit(types.ADD_MESSAGE, message);
    }
  }
};

export const setMessages = ({ dispatch }, messages) => {
  messages.forEach((msg) => {
    dispatch('addDuoChatMessage', msg);
  });
};

export const setLoading = ({ commit }, flag = true) => {
  commit(types.SET_LOADING, flag);
};
