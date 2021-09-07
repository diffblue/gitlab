import Api from '~/api';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';

import { parseCodeclimateMetrics } from '~/reports/codequality_report/store/utils/codequality_parser';
import getCodeQualityViolations from '../graphql/queries/get_code_quality_violations.query.graphql';
import { VIEW_EVENT_NAME } from './constants';
import * as types from './mutation_types';
import { gqClient } from './utils';

export const setPage = ({ state, commit, dispatch }, page) => {
  if (gon.features?.graphqlCodeQualityFullReport) {
    const { currentPage, startCursor, endCursor } = state.pageInfo;

    if (page > currentPage) {
      commit(types.SET_PAGE, {
        after: endCursor,
        currentPage: page,
      });
    } else {
      commit(types.SET_PAGE, {
        after: startCursor,
        currentPage: page,
      });
    }
    return dispatch('fetchReport');
  }
  return commit(types.SET_PAGE, { page });
};

export const requestReport = ({ commit }) => {
  commit(types.REQUEST_REPORT);

  Api.trackRedisHllUserEvent(VIEW_EVENT_NAME);
};
export const receiveReportSuccess = ({ state, commit }, data) => {
  if (gon.features?.graphqlCodeQualityFullReport) {
    const parsedIssues = parseCodeclimateMetrics(
      data.edges.map((edge) => edge.node),
      state.blobPath,
    );
    return commit(types.RECEIVE_REPORT_SUCCESS_GRAPHQL, { data, parsedIssues });
  }
  const parsedIssues = parseCodeclimateMetrics(data, state.blobPath);
  return commit(types.RECEIVE_REPORT_SUCCESS, parsedIssues);
};
export const receiveReportError = ({ commit }, error) => commit(types.RECEIVE_REPORT_ERROR, error);

export const fetchReport = ({ state, dispatch }) => {
  dispatch('requestReport');

  if (gon.features?.graphqlCodeQualityFullReport) {
    const { projectPath, pipelineIid, pageInfo } = state;
    const variables = {
      projectPath,
      iid: pipelineIid,
      first: pageInfo.first,
      after: pageInfo.after,
    };

    return gqClient
      .query({
        query: getCodeQualityViolations,
        variables,
      })
      .then(({ data }) => {
        if (!state.blobPath) throw new Error();
        dispatch('receiveReportSuccess', data.project.pipeline.codeQualityReports);
      })
      .catch((error) => {
        dispatch('receiveReportError', error);
        createFlash({
          message: s__('ciReport|There was an error fetching the codequality report.'),
        });
      });
  }
  return axios
    .get(state.endpoint)
    .then(({ data }) => {
      if (!state.blobPath) throw new Error();
      dispatch('receiveReportSuccess', data);
    })
    .catch((error) => {
      dispatch('receiveReportError', error);
      createFlash({
        message: s__('ciReport|There was an error fetching the codequality report.'),
      });
    });
};
