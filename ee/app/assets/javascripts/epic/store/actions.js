import epicDetailsQuery from 'shared_queries/epic/epic_details.query.graphql';
import createFlash from '~/flash';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';

import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

import { statusType, statusEvent } from '../constants';
import epicUtils from '../utils/epic_utils';

import * as types from './mutation_types';

export const setEpicMeta = ({ commit }, meta) => commit(types.SET_EPIC_META, meta);

export const setEpicData = ({ commit }, data) => commit(types.SET_EPIC_DATA, data);

export const fetchEpicDetails = ({ state, dispatch }) => {
  const variables = {
    fullPath: state.fullPath,
    iid: state.epicIid,
  };

  epicUtils.gqClient
    .query({
      query: epicDetailsQuery,
      variables,
    })
    .then(({ data }) => {
      const participants = data.group.epic.participants.edges.map((participant) => ({
        name: participant.node.name,
        avatar_url: participant.node.avatarUrl,
        web_url: participant.node.webUrl,
      }));

      dispatch('setEpicData', { participants });
    })
    .catch(() => dispatch('requestEpicParticipantsFailure'));
};

export const requestEpicParticipantsFailure = () => {
  createFlash({
    message: __('There was an error getting the epic participants.'),
  });
};

export const requestEpicStatusChange = ({ commit }) => commit(types.REQUEST_EPIC_STATUS_CHANGE);

export const requestEpicStatusChangeSuccess = ({ commit }, data) =>
  commit(types.REQUEST_EPIC_STATUS_CHANGE_SUCCESS, data);

export const requestEpicStatusChangeFailure = ({ commit }) => {
  commit(types.REQUEST_EPIC_STATUS_CHANGE_FAILURE);
  createFlash({
    message: __('Unable to update this epic at this time.'),
  });
};

export const triggerIssuableEvent = (_, { isEpicOpen }) => {
  // Ensure that status change is reflected across the page.
  // As `Close`/`Reopen` button is also present under
  // comment form (part of Notes app) We've wrapped
  // call to `$(document).trigger` within `triggerDocumentEvent`
  // for ease of testing
  epicUtils.triggerDocumentEvent(EVENT_ISSUABLE_VUE_APP_CHANGE, isEpicOpen);
  epicUtils.triggerDocumentEvent('issuable:change', isEpicOpen);
};

export const toggleEpicStatus = ({ state, dispatch }, isEpicOpen) => {
  dispatch('requestEpicStatusChange');

  const statusEventType = isEpicOpen ? statusEvent.close : statusEvent.reopen;
  const queryParam = `epic[state_event]=${statusEventType}`;

  axios
    .put(`${state.endpoint}.json?${encodeURI(queryParam)}`)
    .then(({ data }) => {
      dispatch('requestEpicStatusChangeSuccess', data);
      dispatch('triggerIssuableEvent', { isEpicOpen: data.state === statusType.close });
    })
    .catch(() => {
      dispatch('requestEpicStatusChangeFailure');
      dispatch('triggerIssuableEvent', { isEpicOpen: !isEpicOpen });
    });
};

export const toggleSidebarFlag = ({ commit }, sidebarCollapsed) =>
  commit(types.TOGGLE_SIDEBAR, sidebarCollapsed);
export const toggleContainerClassAndCookie = (_, sidebarCollapsed) => {
  epicUtils.toggleContainerClass('right-sidebar-expanded');
  epicUtils.toggleContainerClass('right-sidebar-collapsed');

  epicUtils.setCollapsedGutter(sidebarCollapsed);
};
export const toggleSidebar = ({ dispatch }, { sidebarCollapsed }) => {
  dispatch('toggleContainerClassAndCookie', !sidebarCollapsed);
  dispatch('toggleSidebarFlag', !sidebarCollapsed);
};

/**
 * Methods to handle toggling Todo from sidebar
 */
export const requestEpicTodoToggle = ({ commit }) => commit(types.REQUEST_EPIC_TODO_TOGGLE);
export const requestEpicTodoToggleSuccess = ({ commit }, data) =>
  commit(types.REQUEST_EPIC_TODO_TOGGLE_SUCCESS, data);
export const requestEpicTodoToggleFailure = ({ commit, state }, data) => {
  commit(types.REQUEST_EPIC_TODO_TOGGLE_FAILURE, data);

  if (state.todoExists) {
    createFlash({
      message: __('There was an error deleting the To Do.'),
    });
  } else {
    createFlash({
      message: __('There was an error adding a To Do.'),
    });
  }
};
export const triggerTodoToggleEvent = (_, { count }) => {
  const event = new CustomEvent('todo:toggle', {
    detail: {
      count,
    },
  });

  document.dispatchEvent(event);
};
export const toggleTodo = ({ state, dispatch }) => {
  let reqPromise;

  dispatch('requestEpicTodoToggle');

  if (!state.todoExists) {
    reqPromise = axios.post(state.todoPath, {
      issuable_id: state.epicId,
      issuable_type: 'epic',
    });
  } else {
    reqPromise = axios.delete(state.todoDeletePath);
  }

  reqPromise
    .then(({ data }) => {
      dispatch('triggerTodoToggleEvent', { count: data.count });
      dispatch('requestEpicTodoToggleSuccess', { todoDeletePath: data.delete_path });
    })
    .catch(() => {
      dispatch('requestEpicTodoToggleFailure');
    });
};

/**
 * Methods to handle Epic confidentiality manipulations from sidebar
 */
export const updateConfidentialityOnIssuable = ({ commit }, confidential) => {
  commit(types.SET_EPIC_CONFIDENTIAL, confidential);
};

/**
 * Methods to handle Epic create from Epics index page
 */
export const setEpicCreateTitle = ({ commit }, data) => commit(types.SET_EPIC_CREATE_TITLE, data);
export const setEpicCreateConfidential = ({ commit }, data) =>
  commit(types.SET_EPIC_CREATE_CONFIDENTIAL, data);
export const requestEpicCreate = ({ commit }) => commit(types.REQUEST_EPIC_CREATE);
export const requestEpicCreateSuccess = (_, webUrl) => visitUrl(webUrl);
export const requestEpicCreateFailure = ({ commit }) => {
  commit(types.REQUEST_EPIC_CREATE_FAILURE);
  createFlash({
    message: __('Error creating epic'),
  });
};
export const createEpic = ({ state, dispatch }) => {
  dispatch('requestEpicCreate');
  axios
    .post(state.endpoint, {
      title: state.newEpicTitle,
      confidential: state.newEpicConfidential,
    })
    .then(({ data }) => {
      dispatch('requestEpicCreateSuccess', data.web_url);
    })
    .catch(() => {
      dispatch('requestEpicCreateFailure');
    });
};
