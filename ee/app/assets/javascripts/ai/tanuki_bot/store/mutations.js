import { isObject } from 'lodash';
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
    if (isObject(data)) {
      const { msg, content, ...rest } = data;
      state.messages.push({
        id: state.messages.length,
        role: MESSAGE_TYPES.TANUKI,
        ...rest,
        content: content || msg,
      });
    } else {
      state.messages.push({
        id: state.messages.length,
        role: MESSAGE_TYPES.TANUKI,
        content: data,
      });
    }
  },
  [types.ADD_ERROR_MESSAGE](state, msg) {
    state.messages.push({
      id: state.messages.length,
      role: MESSAGE_TYPES.TANUKI,
      content: msg ? msg.content || msg.errors.join(' ') : '',
      errors: [ERROR_MESSAGE],
    });
  },
};
