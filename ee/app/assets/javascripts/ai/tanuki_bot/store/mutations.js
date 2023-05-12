import { MESSAGE_TYPES, ERROR_MESSAGE } from '../constants';
import * as types from './mutation_types';

export default {
  [types.SET_LOADING](state, loading) {
    state.loading = loading;
  },
  [types.ADD_USER_MESSAGE](state, msg) {
    state.messages.push({
      id: state.messages.length,
      role: MESSAGE_TYPES.USER,
      content: msg,
    });
  },
  [types.ADD_TANUKI_MESSAGE](state, data) {
    const { msg, content, ...rest } = data;
    state.messages.push({
      id: state.messages.length,
      role: MESSAGE_TYPES.TANUKI,
      ...rest,
      content: content || msg,
    });
  },
  [types.ADD_ERROR_MESSAGE](state) {
    state.messages.push({
      id: state.messages.length,
      role: MESSAGE_TYPES.TANUKI,
      content: ERROR_MESSAGE,
    });
  },
};
