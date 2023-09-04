import { isObject } from 'lodash';
import { GENIE_CHAT_MODEL_ROLES, CHAT_MESSAGE_TYPES } from '../../constants';
import * as types from './mutation_types';

export default {
  [types.ADD_MESSAGE](state, newMessageData) {
    if (newMessageData && isObject(newMessageData) && Object.values(newMessageData).length) {
      if (newMessageData.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.system) {
        return;
      }
      let isLastMessage = false;

      const getExistingMesagesIndex = (role) =>
        state.messages.findIndex(
          (msg) => msg.requestId === newMessageData.requestId && msg.role.toLowerCase() === role,
        );
      const userMessageWithRequestIdIndex = getExistingMesagesIndex(GENIE_CHAT_MODEL_ROLES.user);
      const assistantMessageWithRequestIdIndex = getExistingMesagesIndex(
        GENIE_CHAT_MODEL_ROLES.assistant,
      );
      const assistantMessageExists = assistantMessageWithRequestIdIndex > -1;
      const userMessageExists = userMessageWithRequestIdIndex > -1;

      const isUserMesasge = newMessageData.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.user;
      const isAssistantMessage =
        newMessageData.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.assistant;

      if (assistantMessageExists && isAssistantMessage) {
        // We update the existing ASSISTANT message object instead of pushing a new one
        state.messages.splice(assistantMessageWithRequestIdIndex, 1, {
          ...state.messages[assistantMessageWithRequestIdIndex],
          ...newMessageData,
        });
      } else if (userMessageExists && isUserMesasge) {
        // We update the existing USER message object instead of pushing a new one
        state.messages.splice(userMessageWithRequestIdIndex, 1, {
          ...state.messages[userMessageWithRequestIdIndex],
          ...newMessageData,
        });
      } else if (userMessageExists && isAssistantMessage) {
        // We add the new ASSISTANT message
        isLastMessage = userMessageWithRequestIdIndex === state.messages.length - 1;
        state.messages.splice(userMessageWithRequestIdIndex + 1, 0, newMessageData);
      } else {
        // It's the new message, so just push it to the end of the Array
        state.messages.push(newMessageData);
      }
      if (isLastMessage) {
        state.loading = false;
      }
    }
  },
  [types.SET_LOADING](state, loading) {
    state.loading = loading;
  },
  [types.ADD_TOOL_MESSAGE](state, toolMessage) {
    if (
      (toolMessage.role.toLowerCase() !== GENIE_CHAT_MODEL_ROLES.system &&
        toolMessage.type !== CHAT_MESSAGE_TYPES.tool) ||
      !state.loading
    ) {
      return;
    }
    state.toolMessage = toolMessage;
  },
};
