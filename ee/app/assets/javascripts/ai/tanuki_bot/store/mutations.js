import { MESSAGE_TYPES, ERROR_MESSAGE } from '../constants';
import * as types from './mutation_types';

export default {
  [types.SET_LOADING](state, loading) {
    state.loading = loading;
  },
  [types.ADD_USER_MESSAGE](state, msg) {
    state.messages.push({ id: state.messages.length, type: MESSAGE_TYPES.USER, msg });
  },
  [types.ADD_TANUKI_MESSAGE](state, data) {
    state.messages.push({ id: state.messages.length, type: MESSAGE_TYPES.TANUKI, ...data });
  },
  [types.ADD_ERROR_MESSAGE](state) {
    state.messages.push({
      id: state.messages.length,
      type: MESSAGE_TYPES.TANUKI,
      msg: ERROR_MESSAGE,
    });
  },
};
