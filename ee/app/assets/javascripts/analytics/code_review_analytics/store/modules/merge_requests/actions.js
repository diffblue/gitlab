import API from 'ee/api';
import { createAlert } from '~/alert';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import { filterToQueryObject } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import * as types from './mutation_types';

export const setProjectId = ({ commit }, projectId) => commit(types.SET_PROJECT_ID, projectId);

export const fetchMergeRequests = ({ commit, state, rootState }) => {
  commit(types.REQUEST_MERGE_REQUESTS);

  const { projectId, pageInfo } = state;
  const {
    filters: {
      milestones: { selected: selectedMilestone },
      labels: { selectedList: selectedLabelList },
    },
  } = rootState;

  const filterBarQuery = filterToQueryObject({
    milestone_title: selectedMilestone,
    label_name: selectedLabelList,
  });
  const params = {
    project_id: projectId,
    page: pageInfo.page,
    ...filterBarQuery,
  };

  return API.codeReviewAnalytics(params)
    .then((response) => {
      const { headers, data } = response;
      const normalizedHeaders = normalizeHeaders(headers);
      commit(types.RECEIVE_MERGE_REQUESTS_SUCCESS, {
        pageInfo: parseIntPagination(normalizedHeaders),
        mergeRequests: data,
      });
    })
    .catch(({ response }) => {
      const { status } = response;
      commit(types.RECEIVE_MERGE_REQUESTS_ERROR, status);
      createAlert({
        message: __('An error occurred while loading merge requests.'),
      });
    });
};

export const setPage = ({ commit }, page) => commit(types.SET_PAGE, page);
