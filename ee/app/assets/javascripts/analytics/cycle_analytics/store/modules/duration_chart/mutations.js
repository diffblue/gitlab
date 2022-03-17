import * as types from './mutation_types';

export default {
  [types.SET_LOADING](state, loading) {
    state.isLoading = loading;
  },
  [types.REQUEST_DURATION_DATA](state) {
    state.isLoading = true;
    state.errorCode = null;
    state.errorMessage = '';
  },
  [types.RECEIVE_DURATION_DATA_SUCCESS](state, data) {
    state.durationData = data;
    state.isLoading = false;
    state.errorCode = null;
    state.errorMessage = '';
  },
  [types.RECEIVE_DURATION_DATA_ERROR](state, { errorCode = null, message = '' } = {}) {
    state.errorCode = errorCode;
    state.errorMessage = message;
    state.durationData = [];
    state.isLoading = false;
  },
};
