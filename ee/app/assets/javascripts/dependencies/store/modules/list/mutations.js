import { REPORT_STATUS, SORT_FIELD_ORDER, SORT_ASCENDING, SORT_DESCENDING } from './constants';
import * as types from './mutation_types';

export default {
  [types.SET_DEPENDENCIES_ENDPOINT](state, payload) {
    state.endpoint = payload;
  },
  [types.SET_INITIAL_STATE](state, payload) {
    Object.assign(state, payload);
  },
  [types.REQUEST_DEPENDENCIES](state) {
    state.isLoading = true;
    state.errorLoading = false;
  },
  [types.RECEIVE_DEPENDENCIES_SUCCESS](state, { dependencies, reportInfo, pageInfo }) {
    state.dependencies = dependencies;
    state.pageInfo = pageInfo;
    state.isLoading = false;
    state.errorLoading = false;
    state.reportInfo.status = reportInfo.status;
    state.reportInfo.jobPath = reportInfo.job_path;
    state.reportInfo.generatedAt = reportInfo.generated_at;
    state.initialized = true;
  },
  [types.RECEIVE_DEPENDENCIES_ERROR](state) {
    state.isLoading = false;
    state.errorLoading = true;
    state.dependencies = [];
    state.pageInfo = {};
    state.reportInfo = {
      status: REPORT_STATUS.ok,
      jobPath: '',
      generatedAt: '',
    };
    state.initialized = true;
  },
  [types.SET_SORT_FIELD](state, payload) {
    state.sortField = payload;
    state.sortOrder = SORT_FIELD_ORDER[payload];
  },
  [types.TOGGLE_SORT_ORDER](state) {
    state.sortOrder = state.sortOrder === SORT_ASCENDING ? SORT_DESCENDING : SORT_ASCENDING;
  },
};
