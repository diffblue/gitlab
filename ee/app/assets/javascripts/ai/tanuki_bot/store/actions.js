import { GENIE_CHAT_MODEL_ROLES } from 'ee/ai/constants';
import * as types from './mutation_types';

const proxyMessageContent = (message, propsToUpdate) => {
  return {
    ...message,
    ...propsToUpdate,
    role: message.role || GENIE_CHAT_MODEL_ROLES.user,
  };
};

const parseRawContent = (msgContent) => {
  try {
    const parsedContent = JSON.parse(msgContent);

    // JSON.parse does not throw when parsing Strings that are coerced to primary data types, like Number or Boolean.
    // JSON.parse("1") would return 1 (Number), same as JSON.parse("false"), which returns false (Boolean).
    // We therefore check if the parsed response is really an Object.
    // This will be solved with https://gitlab.com/gitlab-org/gitlab/-/issues/423315 when we no longer receive
    // potential JSON as a string.
    if (typeof parsedContent === 'object') {
      return parsedContent.content;
    }
  } catch {
    // no-op
  }
  return msgContent;
};

export const addDuoChatMessage = async ({ commit }, messageData = { content: '' }) => {
  const { errors = [], content = '' } = messageData || {};
  const msgContent = content || errors.join('; ');

  if (msgContent) {
    const parsedContent = parseRawContent(msgContent);
    const message = proxyMessageContent(messageData, { content: parsedContent });

    if (message.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.system) {
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
