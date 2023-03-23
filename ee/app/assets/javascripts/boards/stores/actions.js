import {
  formatListIssues,
  formatListsPageInfo,
  fullBoardId,
  getMoveData,
  filterVariables,
} from '~/boards/boards_util';
import eventHub from '~/boards/eventhub';
import { defaultClient as gqlClient } from '~/graphql_shared/issuable_client';
import groupBoardMembersQuery from '~/boards/graphql/group_board_members.query.graphql';
import listsIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import projectBoardMembersQuery from '~/boards/graphql/project_board_members.query.graphql';
import actionsCE from '~/boards/stores/actions';
import * as typesCE from '~/boards/stores/mutation_types';
import { TYPENAME_ITERATION, TYPENAME_ITERATIONS_CADENCE } from '~/graphql_shared/constants';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_EPIC, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { fetchPolicies } from '~/lib/graphql';
import { historyPushState, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { mergeUrlParams, removeParams, queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import searchIterationQuery from 'ee/issues/list/queries/search_iterations.query.graphql';
import searchIterationCadencesQuery from 'ee/issues/list/queries/search_iteration_cadences.query.graphql';
import epicBoardListQuery from 'ee/boards/graphql/epic_board_lists_deferred.query.graphql';
import {
  EpicFilterType,
  FilterFields,
  IterationIDs,
  DEFAULT_BOARD_LIST_ITEMS_SIZE,
} from 'ee_else_ce/boards/constants';
import {
  fullEpicBoardId,
  formatEpic,
  formatListEpics,
  formatEpicListsPageInfo,
  formatEpicInput,
  FiltersInfo,
} from '../boards_util';

import epicBoardQuery from '../graphql/epic_board.query.graphql';
import createEpicBoardListMutation from '../graphql/epic_board_list_create.mutation.graphql';
import epicCreateMutation from '../graphql/epic_create.mutation.graphql';
import epicMoveListMutation from '../graphql/epic_move_list.mutation.graphql';
import epicsSwimlanesQuery from '../graphql/epics_swimlanes.query.graphql';
import listUpdateLimitMetricsMutation from '../graphql/list_update_limit_metrics.mutation.graphql';
import listsEpicsQuery from '../graphql/lists_epics.query.graphql';
import listsEpicsWithColorQuery from '../graphql/lists_epics_with_color.query.graphql';
import subGroupsQuery from '../graphql/sub_groups.query.graphql';
import currentIterationQuery from '../graphql/board_current_iteration.query.graphql';
import updateBoardEpicUserPreferencesMutation from '../graphql/update_board_epic_user_preferences.mutation.graphql';

import * as types from './mutation_types';

const fetchAndFormatListIssues = (state, { fetchPolicy, ...extraVariables }) => {
  const { fullPath, boardId, boardType, filterParams } = state;

  const variables = {
    fullPath,
    boardId: fullBoardId(boardId),
    filters: { ...filterParams },
    isGroup: boardType === WORKSPACE_GROUP,
    isProject: boardType === WORKSPACE_PROJECT,
    ...extraVariables,
  };

  return gqlClient
    .query({
      query: listsIssuesQuery,
      context: {
        isSingleRequest: true,
      },
      variables,
      fetchPolicy,
    })
    .then(({ data }) => {
      const { lists } = data[boardType].board;
      return { listItems: formatListIssues(lists), listPageInfo: formatListsPageInfo(lists) };
    });
};

const fetchAndFormatListEpics = (state, { fetchPolicy, ...extraVariables }) => {
  const { fullPath, boardId, filterParams } = state;

  const variables = {
    fullPath,
    boardId: fullEpicBoardId(boardId),
    filters: { ...filterParams },
    ...extraVariables,
  };

  const query = gon?.features?.epicColorHighlight ? listsEpicsWithColorQuery : listsEpicsQuery;

  return gqlClient
    .query({
      query,
      context: {
        isSingleRequest: true,
      },
      variables,
      fetchPolicy,
    })
    .then(({ data }) => {
      const { lists } = data.group.board;
      return { listItems: formatListEpics(lists), listPageInfo: formatEpicListsPageInfo(lists) };
    });
};

export { gqlClient };

export default {
  ...actionsCE,

  fetchEpicBoard: ({ commit, dispatch }, { fullPath, boardId }) => {
    commit(types.REQUEST_CURRENT_BOARD);

    const variables = {
      fullPath,
      boardId,
    };

    return gqlClient
      .query({
        query: epicBoardQuery,
        variables,
      })
      .then(({ data }) => {
        if (data.workspace?.errors) {
          commit(types.RECEIVE_BOARD_FAILURE);
        } else {
          const board = data.workspace?.board;
          dispatch('setBoard', board);
        }
      })
      .then(() => {
        dispatch('fetchLists');
        eventHub.$emit('updateTokens');
      })
      .catch(() => commit(types.RECEIVE_BOARD_FAILURE));
  },

  addListNewIssue: async (
    { state: { boardConfig, boardType, fullPath, filterParams }, dispatch, commit },
    issueInputObj,
  ) => {
    const iterationId = issueInputObj.list.iteration?.id || boardConfig.iterationId;
    let { iterationCadenceId } = boardConfig;

    const getCurrentIteration = async (bType, fPath) => {
      const { data = {} } = await gqlClient.query({
        query: currentIterationQuery,
        context: {
          isSingleRequest: true,
        },
        variables: {
          isGroup: bType === WORKSPACE_GROUP,
          fullPath: fPath,
        },
      });

      return data[bType]?.iterations?.nodes?.[0]?.iterationCadence?.id;
    };

    if (!iterationCadenceId && iterationId === IterationIDs.CURRENT) {
      iterationCadenceId = await getCurrentIteration(boardType, fullPath);
    }

    return actionsCE.addListNewIssue(
      {
        state: {
          boardConfig: { ...boardConfig, iterationId, iterationCadenceId },
          boardType,
          fullPath,
          filterParams,
        },
        dispatch,
        commit,
      },
      issueInputObj,
    );
  },

  setFilters: ({ commit, dispatch, state: { issuableType } }, filters) => {
    const filtersCopy = { ...filters };

    if (filters.groupBy === TYPE_EPIC) {
      dispatch('setEpicSwimlanes');
    }

    if (filters?.iterationId) {
      filtersCopy.iterationId = convertToGraphQLId(TYPENAME_ITERATION, filters.iterationId);
    }

    commit(
      types.SET_FILTERS,
      filterVariables({
        filters: filtersCopy,
        issuableType,
        filterInfo: FiltersInfo,
        filterFields: FilterFields,
      }),
    );
  },

  fetchIterations({ state, commit }, title) {
    commit(types.RECEIVE_ITERATIONS_REQUEST);

    const { fullPath, boardType } = state;

    const id = Number(title);
    let variables = { fullPath, search: title, isProject: boardType === WORKSPACE_PROJECT };

    if (!Number.isNaN(id) && title !== '') {
      variables = { fullPath, id, isProject: boardType === WORKSPACE_PROJECT };
    }

    return gqlClient
      .query({
        query: searchIterationQuery,
        variables,
      })
      .then(({ data }) => {
        const errors = data[boardType]?.errors;
        const iterations = data[boardType]?.iterations.nodes;

        if (errors?.[0]) {
          throw new Error(errors[0]);
        }

        commit(types.RECEIVE_ITERATIONS_SUCCESS, iterations);

        return iterations;
      })
      .catch((e) => {
        commit(types.RECEIVE_ITERATIONS_FAILURE);
        throw e;
      });
  },

  fetchIterationCadences({ state, commit }, title) {
    commit(types.RECEIVE_CADENCES_REQUEST);

    const { fullPath, boardType } = state;

    const id = Number(title);
    let variables = { fullPath, title, isProject: boardType === WORKSPACE_PROJECT };

    if (!Number.isNaN(id) && title !== '') {
      variables = {
        fullPath,
        id: convertToGraphQLId(TYPENAME_ITERATIONS_CADENCE, id),
        isProject: boardType === WORKSPACE_PROJECT,
      };
    }

    return gqlClient
      .query({
        query: searchIterationCadencesQuery,
        variables,
      })
      .then(({ data }) => {
        const errors = data[boardType]?.errors;
        const cadences = data[boardType]?.iterationCadences?.nodes;

        if (errors?.[0]) {
          throw new Error(errors[0]);
        }

        commit(types.RECEIVE_CADENCES_SUCCESS, cadences);

        return cadences;
      })
      .catch((e) => {
        commit(types.RECEIVE_CADENCES_FAILURE);
        throw e;
      });
  },

  performSearch({ dispatch, getters }, { resetLists = false } = {}) {
    dispatch(
      'setFilters',
      convertObjectPropsToCamelCase(queryToObject(window.location.search, { gatherArrays: true })),
    );

    if (getters.isSwimlanesOn) {
      dispatch('resetEpics');
      dispatch('fetchEpicsSwimlanes');
    }

    dispatch('fetchLists', { resetLists });
    dispatch('resetIssues');
  },

  fetchEpicsSwimlanes({ state, commit }, { fetchNext = false } = {}) {
    const { fullPath, boardId, boardType, filterParams, epicsEndCursor } = state;

    if (fetchNext) {
      commit(types.REQUEST_MORE_EPICS);
    }

    const variables = {
      fullPath,
      boardId: `gid://gitlab/Board/${boardId}`,
      issueFilters: filterParams,
      isGroup: boardType === WORKSPACE_GROUP,
      isProject: boardType === WORKSPACE_PROJECT,
      after: fetchNext ? epicsEndCursor : undefined,
    };

    return gqlClient
      .query({
        query: epicsSwimlanesQuery,
        variables,
      })
      .then(({ data }) => {
        const { epics } = data[boardType].board;
        const epicsFormatted = epics.nodes;

        if (epicsFormatted) {
          commit(types.RECEIVE_EPICS_SUCCESS, {
            epics: epicsFormatted,
            canAdminEpic: epicsFormatted[0]?.userPermissions?.adminEpic,
            hasMoreEpics: epics.pageInfo?.hasNextPage,
            epicsEndCursor: epics.pageInfo?.endCursor,
          });
        }
      })
      .catch(() => commit(types.RECEIVE_SWIMLANES_FAILURE));
  },

  fetchIssuesForEpic: ({ state, commit }, epicId) => {
    commit(types.REQUEST_ISSUES_FOR_EPIC, epicId);

    const { filterParams } = state;

    const variables = {
      filters: { ...filterParams, epicId },
    };

    return fetchAndFormatListIssues(state, variables)
      .then(({ listItems }) => {
        commit(types.RECEIVE_ISSUES_FOR_EPIC_SUCCESS, { ...listItems, epicId });
      })
      .catch(() => commit(types.RECEIVE_ISSUES_FOR_EPIC_FAILURE, epicId));
  },

  updateBoardEpicUserPreferences({ commit, state }, { epicId, collapsed }) {
    const { boardId } = state;

    const variables = {
      boardId: fullBoardId(boardId),
      epicId,
      collapsed,
    };

    return gqlClient
      .mutate({
        mutation: updateBoardEpicUserPreferencesMutation,
        variables,
      })
      .then(({ data }) => {
        if (data?.updateBoardEpicUserPreferences?.errors.length) {
          throw new Error();
        }

        const { epicUserPreferences: userPreferences } = data.updateBoardEpicUserPreferences;
        commit(types.SET_BOARD_EPIC_USER_PREFERENCES, { epicId, userPreferences });
      })
      .catch(() => {
        commit(types.SET_BOARD_EPIC_USER_PREFERENCES, {
          epicId,
          userPreferences: {
            collapsed: !collapsed,
          },
        });
      });
  },

  setShowLabels({ commit }, val) {
    commit(types.SET_SHOW_LABELS, val);
  },

  updateListWipLimit({ commit, dispatch }, { maxIssueCount, listId }) {
    return gqlClient
      .mutate({
        mutation: listUpdateLimitMetricsMutation,
        variables: {
          input: {
            listId,
            maxIssueCount,
          },
        },
      })
      .then(({ data }) => {
        if (data?.boardListUpdateLimitMetrics?.errors.length) {
          throw new Error();
        }

        commit(types.UPDATE_LIST_SUCCESS, {
          listId,
          list: data.boardListUpdateLimitMetrics?.list,
        });
      })
      .catch(() => {
        dispatch('handleUpdateListFailure');
      });
  },

  fetchItemsForList: (
    { state, commit, getters },
    { listId, fetchNext = false, noEpicIssues = false },
  ) => {
    if (!listId) return null;

    commit(types.REQUEST_ITEMS_FOR_LIST, { listId, fetchNext });

    const { epicId, ...filterParams } = state.filterParams;

    if (noEpicIssues && epicId !== undefined) {
      return null;
    }

    const variables = {
      id: listId,
      filters: noEpicIssues
        ? { ...filterParams, epicWildcardId: EpicFilterType.none.toUpperCase() }
        : { ...filterParams, epicId },
      after: fetchNext ? state.pageInfoByListId[listId].endCursor : undefined,
      first: DEFAULT_BOARD_LIST_ITEMS_SIZE,
      ...(!fetchNext ? { fetchPolicy: fetchPolicies.NO_CACHE } : {}),
    };

    if (getters.isEpicBoard) {
      return fetchAndFormatListEpics(state, variables)
        .then(({ listItems, listPageInfo }) => {
          commit(types.RECEIVE_ITEMS_FOR_LIST_SUCCESS, {
            listItems,
            listPageInfo,
            listId,
            noEpicIssues,
          });
        })
        .catch(() => commit(types.RECEIVE_ITEMS_FOR_LIST_FAILURE, listId));
    }

    return fetchAndFormatListIssues(state, variables)
      .then(({ listItems, listPageInfo }) => {
        commit(types.RECEIVE_ITEMS_FOR_LIST_SUCCESS, {
          listItems,
          listPageInfo,
          listId,
          noEpicIssues,
        });
      })
      .catch(() => commit(types.RECEIVE_ITEMS_FOR_LIST_FAILURE, listId));
  },

  toggleEpicSwimlanes: ({ state, commit, dispatch }) => {
    commit(types.TOGGLE_EPICS_SWIMLANES);

    if (state.isShowingEpicsSwimlanes) {
      historyPushState(
        mergeUrlParams({ group_by: TYPE_EPIC }, window.location.href, {
          spreadArrays: true,
        }),
      );
      dispatch('fetchEpicsSwimlanes');
      dispatch('fetchLists');
    } else {
      historyPushState(removeParams(['group_by']), window.location.href, true);
    }
  },

  setEpicSwimlanes: ({ commit }) => {
    commit(types.SET_EPICS_SWIMLANES);
  },

  doneLoadingSwimlanesItems: ({ commit }) => {
    commit(types.DONE_LOADING_SWIMLANES_ITEMS);
  },

  resetEpics: ({ commit }) => {
    commit(types.RESET_EPICS);
  },

  setActiveItemWeight: async ({ commit }, { weight, id }) => {
    commit(typesCE.UPDATE_BOARD_ITEM_BY_ID, {
      itemId: id,
      prop: 'weight',
      value: weight,
    });
  },

  setActiveItemHealthStatus: ({ commit, getters }, healthStatus) => {
    const { activeBoardItem } = getters;
    commit(typesCE.UPDATE_BOARD_ITEM_BY_ID, {
      itemId: activeBoardItem.id,
      prop: 'healthStatus',
      value: healthStatus,
    });
  },

  moveItem: ({ getters, dispatch }, params) => {
    if (!getters.isEpicBoard) {
      dispatch('moveIssue', params);
    } else {
      dispatch('moveEpic', params);
    }
  },

  moveIssue: ({ dispatch, state }, params) => {
    const { itemId, epicId } = params;
    const moveData = getMoveData(state, params);

    dispatch('moveIssueCard', moveData);
    dispatch('updateMovedIssue', moveData);
    dispatch('updateEpicForIssue', { itemId, epicId });
    dispatch('updateIssueOrder', {
      moveData,
      mutationVariables: { epicId },
    });
  },

  updateEpicForIssue: ({ commit, state: { boardItems } }, { itemId, epicId }) => {
    const issue = boardItems[itemId];

    if (epicId === null) {
      commit(types.UPDATE_BOARD_ITEM_BY_ID, {
        itemId: issue.id,
        prop: 'epic',
        value: null,
      });
    } else if (epicId !== undefined) {
      commit(types.UPDATE_BOARD_ITEM_BY_ID, {
        itemId: issue.id,
        prop: 'epic',
        value: { id: epicId },
      });
    }
  },

  moveEpic: ({ state, commit }, params) => {
    const {
      itemId,
      fromListId,
      toListId,
      moveBeforeId,
      moveAfterId,
      positionInList,
      originalIndex,
      allItemsLoadedInList,
      reordering,
    } = getMoveData(state, params);

    const originalEpic = state.boardItems[itemId];

    commit(types.MOVE_EPIC, {
      originalEpic,
      fromListId,
      toListId,
      moveBeforeId,
      moveAfterId,
      positionInList,
      atIndex: originalIndex,
      allItemsLoadedInList,
      reordering,
    });

    const { boardId, filterParams } = state;

    gqlClient
      .mutate({
        mutation: epicMoveListMutation,
        variables: {
          epicId: itemId,
          boardId: fullEpicBoardId(boardId),
          fromListId,
          toListId,
          moveBeforeId,
          moveAfterId,
          positionInList,
        },
        update(cache) {
          if (reordering) return;

          const updateList = (listId, summationFunction) => {
            const movingList = cache.readQuery({
              query: epicBoardListQuery,
              variables: { id: listId, filters: filterParams },
            });

            const updatedMovingList = {
              epicBoardList: {
                __typename: 'EpicList',
                id: movingList.epicBoardList.id,
                metadata: {
                  __typename: 'EpicListMetadata',
                  epicsCount: movingList.epicBoardList.metadata.epicsCount,
                  totalWeight: summationFunction(
                    movingList.epicBoardList.metadata.totalWeight,
                    Number(
                      originalEpic.descendantWeightSum.openedIssues +
                        originalEpic.descendantWeightSum.closedIssues,
                    ),
                  ),
                },
              },
            };
            cache.writeQuery({
              query: epicBoardListQuery,
              variables: { id: listId, filters: filterParams },
              data: updatedMovingList,
            });
          };

          updateList(fromListId, (a, b) => a - b);
          updateList(toListId, (a, b) => a + b);
        },
      })
      .then(({ data }) => {
        if (data?.epicMoveList?.errors.length) {
          throw new Error();
        }
      })
      .catch(() =>
        commit(types.MOVE_EPIC_FAILURE, { originalEpic, fromListId, toListId, originalIndex }),
      );
  },

  fetchAssignees({ state, commit }, search) {
    commit(types.RECEIVE_ASSIGNEES_REQUEST);

    const { fullPath, boardType } = state;

    const variables = {
      fullPath,
      search,
    };

    let query;
    if (boardType === WORKSPACE_PROJECT) {
      query = projectBoardMembersQuery;
    }
    if (boardType === WORKSPACE_GROUP) {
      query = groupBoardMembersQuery;
    }

    if (!query) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      throw new Error('Unknown board type');
    }

    return gqlClient
      .query({
        query,
        variables,
      })
      .then(({ data }) => {
        const [firstError] = data.workspace.errors || [];
        const assignees = data.workspace.assignees.nodes
          .filter((x) => x?.user)
          .map(({ user }) => user);

        if (firstError) {
          throw new Error(firstError);
        }
        commit(
          types.RECEIVE_ASSIGNEES_SUCCESS,
          // User field is nullable and we only want to display non-null users
          assignees,
        );
      })
      .catch((e) => {
        commit(types.RECEIVE_ASSIGNEES_FAILURE);
        throw e;
      });
  },

  fetchSubGroups: ({ commit, state }, { search = '', fetchNext = false } = {}) => {
    commit(types.REQUEST_SUB_GROUPS, fetchNext);

    const { fullPath } = state;

    const variables = {
      fullPath,
      search: search !== '' ? search : undefined,
      after: fetchNext ? state.subGroupsFlags.pageInfo.endCursor : undefined,
    };

    return gqlClient
      .query({
        query: subGroupsQuery,
        variables,
      })
      .then(({ data }) => {
        const { id, name, fullName, descendantGroups, __typename } = data.group;
        const currentGroup = {
          __typename,
          id,
          name,
          fullName,
          fullPath: data.group.fullPath,
        };
        const subGroups = [currentGroup, ...descendantGroups.nodes];
        commit(types.RECEIVE_SUB_GROUPS_SUCCESS, {
          subGroups,
          pageInfo: descendantGroups.pageInfo,
          fetchNext,
        });
        commit(types.SET_SELECTED_GROUP, currentGroup);
      })
      .catch(() => commit(types.RECEIVE_SUB_GROUPS_FAILURE));
  },

  setSelectedGroup: ({ commit }, group) => {
    commit(types.SET_SELECTED_GROUP, group);
  },

  createList: (
    { getters, dispatch },
    { backlog, labelId, milestoneId, assigneeId, iterationId },
  ) => {
    if (!getters.isEpicBoard) {
      dispatch('createIssueList', { backlog, labelId, milestoneId, assigneeId, iterationId });
    } else {
      dispatch('createEpicList', { backlog, labelId });
    }
  },

  createEpicList: ({ state, commit, dispatch, getters }, { backlog, labelId }) => {
    const { boardId } = state;

    const existingList = getters.getListByLabelId(labelId);

    if (existingList) {
      dispatch('highlightList', existingList.id);
      return;
    }

    gqlClient
      .mutate({
        mutation: createEpicBoardListMutation,
        variables: {
          boardId: fullEpicBoardId(boardId),
          backlog,
          labelId,
        },
      })
      .then(({ data }) => {
        if (data?.epicBoardListCreate?.errors.length) {
          commit(types.CREATE_LIST_FAILURE, data.epicBoardListCreate.errors[0]);
        } else {
          const list = data.epicBoardListCreate?.list;
          dispatch('addList', list);
          dispatch('highlightList', list.id);
        }
      })
      .catch((e) => {
        commit(types.CREATE_LIST_FAILURE);
        throw e;
      });
  },

  addListNewEpic: (
    { state: { boardConfig }, dispatch, commit },
    { epicInput, list, placeholderId = `tmp-${new Date().getTime()}` },
  ) => {
    const placeholderEpic = {
      ...epicInput,
      id: placeholderId,
      isLoading: true,
      labels: [],
      assignees: [],
    };

    dispatch('addListItem', { list, item: placeholderEpic, position: 0, inProgress: true });

    gqlClient
      .mutate({
        mutation: epicCreateMutation,
        variables: { input: formatEpicInput(epicInput, boardConfig) },
      })
      .then(({ data }) => {
        if (data.createEpic.errors?.length) {
          throw new Error(data.createEpic.errors[0]);
        }

        const rawEpic = data.createEpic?.epic;
        const formattedEpic = formatEpic(rawEpic);
        dispatch('removeListItem', { listId: list.id, itemId: placeholderId });
        dispatch('addListItem', { list, item: formattedEpic, position: 0 });
      })
      .catch(() => {
        dispatch('removeListItem', { listId: list.id, itemId: placeholderId });
        commit(
          types.SET_ERROR,
          s__('Boards|An error occurred while creating the epic. Please try again.'),
        );
      });
  },

  setActiveBoardItemLabels: ({ getters, dispatch }, params) => {
    if (!getters.isEpicBoard) {
      dispatch('setActiveIssueLabels', params);
    } else {
      dispatch('setActiveEpicLabels', params);
    }
  },

  setActiveEpicLabels: async ({ commit, getters }, input) => {
    const { activeBoardItem } = getters;

    let labels = input?.labels || [];
    if (input.removeLabelIds) {
      labels = activeBoardItem.labels.filter(
        (label) => input.removeLabelIds[0] !== getIdFromGraphQLId(label.id),
      );
    }
    commit(types.UPDATE_BOARD_ITEM_BY_ID, {
      itemId: input.id || activeBoardItem.id,
      prop: 'labels',
      value: labels,
    });
  },

  setActiveBoardItemColor: ({ getters, dispatch }, params) => {
    if (getters.isEpicBoard) {
      dispatch('setActiveEpicColor', params);
    }
  },

  setActiveEpicColor: async ({ commit, getters }, input) => {
    const { activeBoardItem } = getters;

    commit(types.UPDATE_BOARD_ITEM_BY_ID, {
      itemId: input.id || activeBoardItem.id,
      prop: 'color',
      value: input.color.color,
    });
  },

  setFullBoardIssuesCount: ({ commit }, { listId, count }) => {
    commit(types.UPDATE_FULL_BOARD_ISSUES_COUNT, { listId, count });
  },
};
