import { union, unionBy } from 'lodash';
import Vue from 'vue';
import { moveItemListHelper } from '~/boards/boards_util';
import mutationsCE, { addItemToList, removeItemFromList } from '~/boards/stores/mutations';
import { TYPE_EPIC } from '~/issues/constants';
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

  [mutationTypes.RECEIVE_ITEMS_FOR_LIST_SUCCESS]: (state, { listItems, listPageInfo, listId }) => {
    const { listData, boardItems } = listItems;
    Vue.set(state, 'boardItems', { ...state.boardItems, ...boardItems });
    Vue.set(
      state.boardItemsByListId,
      listId,
      union(state.boardItemsByListId[listId] || [], listData[listId]),
    );
    Vue.set(state.pageInfoByListId, listId, listPageInfo[listId]);
    Vue.set(state.listsFlags[listId], 'isLoading', false);
    Vue.set(state.listsFlags[listId], 'isLoadingMore', false);
  },

  [mutationTypes.RECEIVE_ITEMS_FOR_LIST_FAILURE]: (state, listId) => {
    state.error =
      state.issuableType === TYPE_EPIC
        ? ErrorMessages.fetchEpicsError
        : ErrorMessages.fetchIssueError;
    Vue.set(state.listsFlags, listId, { isLoading: false, isLoadingMore: false });
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

  [mutationTypes.RECEIVE_CADENCES_REQUEST](state) {
    state.iterationCadencesLoading = true;
  },

  [mutationTypes.RECEIVE_CADENCES_SUCCESS](state, cadences) {
    state.iterationCadences = cadences;
    state.iterationCadencesLoading = false;
  },

  [mutationTypes.RECEIVE_CADENCES_FAILURE](state) {
    state.iterationCadencesLoading = false;
    state.error = __('Failed to load iteration cadences.');
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
    {
      originalEpic,
      fromListId,
      toListId,
      moveBeforeId,
      moveAfterId,
      atIndex,
      positionInList,
      allItemsLoadedInList,
      reordering,
    },
  ) => {
    const fromList = state.boardLists[fromListId];
    const toList = state.boardLists[toListId];

    const epic = moveItemListHelper(originalEpic, fromList, toList);
    Vue.set(state.boardItems, epic.id, epic);

    removeItemFromList({ state, listId: fromListId, itemId: epic.id, reordering });

    if (reordering && !allItemsLoadedInList && positionInList === -1) {
      return;
    }

    addItemToList({
      state,
      listId: toListId,
      itemId: epic.id,
      moveBeforeId,
      moveAfterId,
      atIndex,
      positionInList,
      allItemsLoadedInList,
      reordering,
    });
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

  [mutationTypes.REQUEST_SUB_GROUPS]: (state, fetchNext) => {
    Vue.set(state, 'subGroupsFlags', {
      [fetchNext ? 'isLoadingMore' : 'isLoading']: true,
      pageInfo: state.subGroupsFlags.pageInfo,
    });
  },

  [mutationTypes.RECEIVE_SUB_GROUPS_SUCCESS]: (state, { subGroups, pageInfo, fetchNext }) => {
    Vue.set(state, 'subGroups', fetchNext ? [...state.subGroups, ...subGroups] : subGroups);
    Vue.set(state, 'subGroupsFlags', { isLoading: false, isLoadingMore: false, pageInfo });
  },

  [mutationTypes.RECEIVE_SUB_GROUPS_FAILURE]: (state) => {
    state.error = s__('Boards|An error occurred while fetching child groups. Please try again.');
    Vue.set(state, 'subGroupsFlags', { isLoading: false, isLoadingMore: false });
  },

  [mutationTypes.SET_SELECTED_GROUP]: (state, group) => {
    state.selectedGroup = group;
  },

  [mutationTypes.UPDATE_FULL_BOARD_ISSUES_COUNT]: (state, { listId, count }) => {
    Vue.set(state.fullBoardIssuesCount, listId, count);
  },
};
