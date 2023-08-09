import { isObject } from 'lodash';
import { GENIE_CHAT_MODEL_ROLES } from '../../constants';
import * as types from './mutation_types';

export default {
  [types.ADD_MESSAGE](state, newMessageData) {
    if (newMessageData && isObject(newMessageData) && Object.values(newMessageData).length) {
      if (newMessageData.role.toLowerCase() === GENIE_CHAT_MODEL_ROLES.tool) {
        return;
      }
      const index = state.messages.findIndex((msg) => msg.requestId === newMessageData.requestId);
      const hasMsgWithRequestId = index > -1;
      const msgWithRequestId = hasMsgWithRequestId && state.messages[index];
      let isLastMessage = false;

      if (hasMsgWithRequestId) {
        if (msgWithRequestId.role.toLowerCase() === newMessageData.role.toLowerCase()) {
          // We update the existing message object instead of pushing a new one
          state.messages[index] = {
            ...msgWithRequestId,
            ...newMessageData,
          };
        } else {
          // We add the new ASSISTANT message
          isLastMessage = index === state.messages.length - 1;
          state.messages.splice(index + 1, 0, newMessageData);
        }
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
    if (toolMessage.role.toLowerCase() !== GENIE_CHAT_MODEL_ROLES.tool || !state.loading) {
      return;
    }
    state.toolMessage = toolMessage;
  },
};
