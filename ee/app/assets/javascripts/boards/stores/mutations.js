import { union, unionBy } from 'lodash';
import Vue from 'vue';
import { moveItemListHelper } from '~/boards/boards_util';
import { issuableTypes } from '~/boards/constants';
import mutationsCE, { addItemToList, removeItemFromList } from '~/boards/stores/mutations';
import { s__, __ } from '~/locale';
import { ErrorMessages } from '../constants';
import * as mutationTypes from './mutation_types';

export default {
  ...mutationsCE,
  [mutationTypes.SET_SHOW_LABELS]: (state, val) => {
    state.isShowingLabels = val;
  },

  [mutationTypes.UPDATE_LIST_SUCCESS]: (state, { listId, list }) => {
    Vue.set(state.boardLists, listId, list);
  },

  [mutationTypes.RECEIVE_ITEMS_FOR_LIST_SUCCESS]: (
    state,
    { listItems, listPageInfo, listId, noEpicIssues },
  ) => {
    const { listData, boardItems, listItemsCount } = listItems;
    Vue.set(state, 'boardItems', { ...state.boardItems, ...boardItems });
    Vue.set(
      state.boardItemsByListId,
      listId,
      union(state.boardItemsByListId[listId] || [], listData[listId]),
    );
    Vue.set(state.pageInfoByListId, listId, listPageInfo[listId]);
    Vue.set(state.listsFlags[listId], 'isLoading', false);
    Vue.set(state.listsFlags[listId], 'isLoadingMore', false);
    if (noEpicIssues) {
      Vue.set(state.listsFlags[listId], 'unassignedIssuesCount', listItemsCount);
    }
  },

  [mutationTypes.RECEIVE_ITEMS_FOR_LIST_FAILURE]: (state, listId) => {
    state.error =
      state.issuableType === issuableTypes.epic
        ? ErrorMessages.fetchEpicsError
        : ErrorMessages.fetchIssueError;
    Vue.set(state.listsFlags, listId, { isLoading: false, isLoadingMore: false });
    Vue.set(state.boardItemsByListId, listId, state.backupItemsList);
  },

  [mutationTypes.REQUEST_ISSUES_FOR_EPIC]: (state, epicId) => {
    Vue.set(state.epicsFlags, epicId, { isLoading: true });
  },

  [mutationTypes.RECEIVE_ISSUES_FOR_EPIC_SUCCESS]: (state, { listData, boardItems, epicId }) => {
    Object.entries(listData).forEach(([listId, list]) => {
      Vue.set(
        state.boardItemsByListId,
        listId,
        union(state.boardItemsByListId[listId] || [], list),
      );
    });

    Vue.set(state, 'boardItems', { ...state.boardItems, ...boardItems });
    Vue.set(state.epicsFlags, epicId, { isLoading: false });
  },

  [mutationTypes.RECEIVE_ISSUES_FOR_EPIC_FAILURE]: (state, epicId) => {
    state.error = s__('Boards|An error occurred while fetching issues. Please reload the page.');
    Vue.set(state.epicsFlags, epicId, { isLoading: false });
  },

  [mutationTypes.TOGGLE_EPICS_SWIMLANES]: (state) => {
    state.isShowingEpicsSwimlanes = !state.isShowingEpicsSwimlanes;
    Vue.set(state, 'epicsSwimlanesFetchInProgress', {
      epicLanesFetchInProgress: true,
      listItemsFetchInProgress: true,
    });
  },

  [mutationTypes.SET_EPICS_SWIMLANES]: (state) => {
    state.isShowingEpicsSwimlanes = true;
    Vue.set(state, 'epicsSwimlanesFetchInProgress', {
      epicLanesFetchInProgress: true,
      listItemsFetchInProgress: true,
    });
  },

  [mutationTypes.DONE_LOADING_SWIMLANES_ITEMS]: (state) => {
    Vue.set(state, 'epicsSwimlanesFetchInProgress', {
      ...state.epicsSwimlanesFetchInProgress,
      listItemsFetchInProgress: false,
    });
    state.error = undefined;
  },

  [mutationTypes.RECEIVE_BOARD_LISTS_SUCCESS]: (state, boardLists) => {
    state.boardLists = boardLists;
  },

  [mutationTypes.RECEIVE_SWIMLANES_FAILURE]: (state) => {
    state.error = s__(
      'Boards|An error occurred while fetching the board swimlanes. Please reload the page.',
    );
    Vue.set(state, 'epicsSwimlanesFetchInProgress', {
      ...state.epicsSwimlanesFetchInProgress,
      epicLanesFetchInProgress: false,
    });
  },

  [mutationTypes.REQUEST_MORE_EPICS]: (state) => {
    Vue.set(state, 'epicsSwimlanesFetchInProgress', {
      ...state.epicsSwimlanesFetchInProgress,
      epicLanesFetchMoreInProgress: true,
    });
  },
  [mutationTypes.RECEIVE_EPICS_SUCCESS]: (
    state,
    { epics, canAdminEpic, hasMoreEpics, epicsEndCursor },
  ) => {
    Vue.set(state, 'epics', unionBy(state.epics || [], epics, 'id'));
    Vue.set(state, 'hasMoreEpics', hasMoreEpics);
    Vue.set(state, 'epicsEndCursor', epicsEndCursor);
    if (canAdminEpic !== undefined) {
      state.canAdminEpic = canAdminEpic;
    }
    Vue.set(state, 'epicsSwimlanesFetchInProgress', {
      ...state.epicsSwimlanesFetchInProgress,
      epicLanesFetchInProgress: false,
      epicLanesFetchMoreInProgress: false,
    });
  },

  [mutationTypes.RESET_EPICS]: (state) => {
    Vue.set(state, 'epics', []);
  },

  [mutationTypes.MOVE_EPIC]: (
    state,
    { originalEpic, fromListId, toListId, moveBeforeId, moveAfterId },
  ) => {
    const fromList = state.boardLists[fromListId];
    const toList = state.boardLists[toListId];

    const epic = moveItemListHelper(originalEpic, fromList, toList);
    Vue.set(state.boardItems, epic.id, epic);

    removeItemFromList({ state, listId: fromListId, itemId: epic.id });
    addItemToList({ state, listId: toListId, itemId: epic.id, moveBeforeId, moveAfterId });
  },

  [mutationTypes.MOVE_EPIC_FAILURE]: (
    state,
    { originalEpic, fromListId, toListId, originalIndex },
  ) => {
    state.error = s__('Boards|An error occurred while moving the epic. Please try again.');
    Vue.set(state.boardItems, originalEpic.id, originalEpic);
    removeItemFromList({ state, listId: toListId, itemId: originalEpic.id });
    addItemToList({
      state,
      listId: fromListId,
      itemId: originalEpic.id,
      atIndex: originalIndex,
    });
  },

  [mutationTypes.SET_BOARD_EPIC_USER_PREFERENCES]: (state, val) => {
    const { userPreferences, epicId } = val;

    const epic = state.epics.filter((currentEpic) => currentEpic.id === epicId)[0];

    if (epic) {
      Vue.set(epic, 'userPreferences', userPreferences);
    }
  },

  [mutationTypes.RECEIVE_MILESTONES_REQUEST](state) {
    state.milestonesLoading = true;
  },

  [mutationTypes.RECEIVE_MILESTONES_SUCCESS](state, milestones) {
    state.milestones = milestones;
    state.milestonesLoading = false;
  },

  [mutationTypes.RECEIVE_MILESTONES_FAILURE](state) {
    state.milestonesLoading = false;
    state.error = __('Failed to load milestones.');
  },

  [mutationTypes.RECEIVE_ITERATIONS_REQUEST](state) {
    state.iterationsLoading = true;
  },

  [mutationTypes.RECEIVE_ITERATIONS_SUCCESS](state, iterations) {
    state.iterations = iterations;
    state.iterationsLoading = false;
  },

  [mutationTypes.RECEIVE_ITERATIONS_FAILURE](state) {
    state.iterationsLoading = false;
    state.error = __('Failed to load iterations.');
  },

  [mutationTypes.RECEIVE_ASSIGNEES_REQUEST](state) {
    state.assigneesLoading = true;
  },

  [mutationTypes.RECEIVE_ASSIGNEES_SUCCESS](state, assignees) {
    state.assignees = assignees;
    state.assigneesLoading = false;
  },

  [mutationTypes.RECEIVE_ASSIGNEES_FAILURE](state) {
    state.assigneesLoading = false;
    state.error = __('Failed to load assignees.');
  },
};
