import { SEVERITY_SORT_ORDER } from './constants';
import * as types from './mutation_types';

export default {
  [types.SET_PAGE](state, pageInfo) {
    Object.assign(state, {
      pageInfo: Object.assign(state.pageInfo, pageInfo),
    });
  },
  [types.REQUEST_REPORT](state) {
    Object.assign(state, { isLoadingCodequality: true });
  },
  [types.RECEIVE_REPORT_SUCCESS_GRAPHQL](state, { data, parsedIssues }) {
    Object.assign(state, {
      isLoadingCodequality: false,
      codequalityIssues: parsedIssues,
      loadingCodequalityFailed: false,
      pageInfo: Object.assign(state.pageInfo, {
        count: data.count,
        ...data.pageInfo,
      }),
    });
  },
  [types.RECEIVE_REPORT_SUCCESS](state, allCodequalityIssues) {
    Object.assign(state, {
      isLoadingCodequality: false,
      allCodequalityIssues: Object.freeze(
        allCodequalityIssues.sort(
          (a, b) => SEVERITY_SORT_ORDER[a.severity] - SEVERITY_SORT_ORDER[b.severity],
        ),
      ),
      pageInfo: Object.assign(state.pageInfo, {
        total: allCodequalityIssues.length,
      }),
    });
  },
  [types.RECEIVE_REPORT_ERROR](state, codeQualityError) {
    Object.assign(state, {
      isLoadingCodequality: false,
      allCodequalityIssues: [],
      codequalityIssues: [],
      loadingCodequalityFailed: true,
      codeQualityError,
      pageInfo: Object.assign(state.pageInfo, {
        total: 0,
        count: 0,
      }),
    });
  },
};
