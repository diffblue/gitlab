import { find } from 'lodash';
import Visibility from 'visibilityjs';
import Api from '~/api';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import { __, s__, n__, sprintf } from '~/locale';
import * as types from './mutation_types';

const API_MINIMUM_QUERY_LENGTH = 3;

let eTagPoll;

export const clearProjectsEtagPoll = () => {
  eTagPoll = null;
};
export const stopProjectsPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};
export const restartProjectsPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};
export const forceProjectsRequest = () => {
  if (eTagPoll) eTagPoll.makeRequest();
};

export const addProjectsToDashboard = ({ state, dispatch }) =>
  axios
    .post(state.projectEndpoints.add, {
      project_ids: state.selectedProjects.map((p) => p.id),
    })
    .then((response) => dispatch('receiveAddProjectsToDashboardSuccess', response.data))
    .catch(() => dispatch('receiveAddProjectsToDashboardError'));

export const toggleSelectedProject = ({ commit, state }, project) => {
  if (!find(state.selectedProjects, { id: project.id })) {
    commit(types.ADD_SELECTED_PROJECT, project);
  } else {
    commit(types.REMOVE_SELECTED_PROJECT, project);
  }
};

export const clearSearchResults = ({ commit }) => {
  commit(types.CLEAR_SEARCH_RESULTS);
};

export const receiveAddProjectsToDashboardSuccess = ({ dispatch, state }, data) => {
  const { added, invalid } = data;

  if (invalid.length) {
    const [firstProject, secondProject, ...rest] = state.selectedProjects
      .filter((project) => invalid.includes(project.id))
      .map((project) => project.name);
    const translationValues = {
      firstProject,
      secondProject,
      rest: rest.join(', '),
    };
    let invalidProjects;
    if (rest.length > 0) {
      invalidProjects = sprintf(
        s__('Dashboard|%{firstProject}, %{rest}, and %{secondProject}'),
        translationValues,
      );
    } else if (secondProject) {
      invalidProjects = sprintf(
        s__('Dashboard|%{firstProject} and %{secondProject}'),
        translationValues,
      );
    } else {
      invalidProjects = firstProject;
    }
    createAlert({
      message: sprintf(
        s__(
          'Dashboard|Unable to add %{invalidProjects}. This dashboard is available for public projects, and private projects in groups with a Premium plan.',
        ),
        {
          invalidProjects,
        },
      ),
    });
  }

  if (added.length) {
    dispatch('forceProjectsRequest');
  }
};

export const receiveAddProjectsToDashboardError = ({ state }) => {
  createAlert({
    message: sprintf(__('Something went wrong, unable to add %{project} to dashboard'), {
      project: n__('project', 'projects', state.selectedProjects.length),
    }),
  });
};

export const fetchProjects = ({ state, dispatch, commit }, page) => {
  if (eTagPoll) return;

  dispatch('requestProjects');

  eTagPoll = new Poll({
    resource: {
      fetchProjects: () => axios.get(state.projectEndpoints.list, { params: { page } }),
    },
    method: 'fetchProjects',
    successCallback: (response) => {
      const {
        data: { projects },
        headers,
      } = response;
      commit(types.RECEIVE_PROJECTS_SUCCESS, { projects, headers });
    },
    errorCallback: () => dispatch('receiveProjectsError'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      dispatch('restartProjectsPolling');
    } else {
      dispatch('stopProjectsPolling');
    }
  });
};

export const requestProjects = ({ commit }) => {
  commit(types.REQUEST_PROJECTS);
};

export const receiveProjectsError = ({ commit }) => {
  commit(types.RECEIVE_PROJECTS_ERROR);
  createAlert({
    message: __('Something went wrong, unable to get projects'),
  });
};

export const removeProject = ({ dispatch }, removePath) => {
  axios
    .delete(removePath)
    .then(() => dispatch('receiveRemoveProjectSuccess'))
    .catch(() => dispatch('receiveRemoveProjectError'));
};

export const receiveRemoveProjectSuccess = ({ dispatch }) => dispatch('forceProjectsRequest');

export const receiveRemoveProjectError = () => {
  createAlert({
    message: __('Something went wrong, unable to delete project'),
  });
};

export const setSearchQuery = ({ commit }, query) => commit(types.SET_SEARCH_QUERY, query);

export const fetchSearchResults = ({ state, dispatch }) => {
  const { searchQuery } = state;
  dispatch('requestSearchResults');

  if (!searchQuery || searchQuery.length < API_MINIMUM_QUERY_LENGTH) {
    dispatch('minimumQueryMessage');
  } else {
    Api.projects(searchQuery, {})
      .then((results) => dispatch('receiveSearchResultsSuccess', results))
      .catch(() => dispatch('receiveSearchResultsError'));
  }
};

export const fetchNextPage = ({ state, dispatch }) => {
  if (state.pageInfo.totalPages <= state.pageInfo.currentPage) {
    return;
  }
  Api.projects(state.searchQuery, { page: state.pageInfo.nextPage })
    .then((results) => dispatch('receiveNextPageSuccess', results))
    .catch(() => dispatch('receiveSearchResultsError'));
};

export const requestSearchResults = ({ commit }) => commit(types.REQUEST_SEARCH_RESULTS);

export const receiveNextPageSuccess = ({ commit }, results) => {
  commit(types.RECEIVE_NEXT_PAGE_SUCCESS, results);
};

export const receiveSearchResultsSuccess = ({ commit }, results) => {
  commit(types.RECEIVE_SEARCH_RESULTS_SUCCESS, results);
};

export const receiveSearchResultsError = ({ commit }) => {
  commit(types.RECEIVE_SEARCH_RESULTS_ERROR);
};

export const setProjectEndpoints = ({ commit }, endpoints) => {
  commit(types.SET_PROJECT_ENDPOINT_LIST, endpoints.list);
  commit(types.SET_PROJECT_ENDPOINT_ADD, endpoints.add);
};

export const minimumQueryMessage = ({ commit }) => {
  commit(types.MINIMUM_QUERY_MESSAGE);
};

export const setProjects = ({ commit }, projects) => {
  commit(types.SET_PROJECTS, projects);
};

export const paginateDashboard = ({ dispatch }, newPage) => {
  return Promise.all([
    dispatch('stopProjectsPolling'),
    dispatch('clearProjectsEtagPoll'),
    dispatch('fetchProjects', newPage),
  ]);
};
