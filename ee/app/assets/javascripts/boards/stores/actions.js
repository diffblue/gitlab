import { pick } from 'lodash';
import Cookies from 'js-cookie';
import axios from '~/lib/utils/axios_utils';
import boardsStore from '~/boards/stores/boards_store';
import { __ } from '~/locale';
import { parseBoolean } from '~/lib/utils/common_utils';
import actionsCE from '~/boards/stores/actions';
import { BoardType, ListType } from '~/boards/constants';
import { EpicFilterType } from '../constants';
import boardsStoreEE from './boards_store_ee';
import * as types from './mutation_types';
import { fullEpicId } from '../boards_util';
import {
  formatBoardLists,
  formatListIssues,
  formatListsPageInfo,
  fullBoardId,
} from '~/boards/boards_util';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import eventHub from '~/boards/eventhub';

import createGqClient, { fetchPolicies } from '~/lib/graphql';
import epicsSwimlanesQuery from '../queries/epics_swimlanes.query.graphql';
import issueSetEpic from '../queries/issue_set_epic.mutation.graphql';
import listsIssuesQuery from '~/boards/queries/lists_issues.query.graphql';
import issueMoveListMutation from '../queries/issue_move_list.mutation.graphql';
import updateBoardEpicUserPreferencesMutation from '../queries/updateBoardEpicUserPreferences.mutation.graphql';

const notImplemented = () => {
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  throw new Error('Not implemented!');
};

export const gqlClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

const fetchAndFormatListIssues = (state, extraVariables) => {
  const { endpoints, boardType, filterParams } = state;
  const { fullPath, boardId } = endpoints;

  const variables = {
    fullPath,
    boardId: fullBoardId(boardId),
    filters: { ...filterParams },
    isGroup: boardType === BoardType.group,
    isProject: boardType === BoardType.project,
    ...extraVariables,
  };

  return gqlClient
    .query({
      query: listsIssuesQuery,
      context: {
        isSingleRequest: true,
      },
      variables,
    })
    .then(({ data }) => {
      const { lists } = data[boardType]?.board;
      return { listIssues: formatListIssues(lists), listPageInfo: formatListsPageInfo(lists) };
    });
};

export default {
  ...actionsCE,

  setFilters: ({ commit }, filters) => {
    const filterParams = pick(filters, [
      'assigneeUsername',
      'authorUsername',
      'epicId',
      'labelName',
      'milestoneTitle',
      'releaseTag',
      'search',
      'weight',
    ]);

    if (filterParams.epicId === EpicFilterType.any || filterParams.epicId === EpicFilterType.none) {
      filterParams.epicWildcardId = filterParams.epicId.toUpperCase();
      filterParams.epicId = undefined;
    } else if (filterParams.epicId) {
      filterParams.epicId = fullEpicId(filterParams.epicId);
    }
    commit(types.SET_FILTERS, filterParams);
  },

  fetchEpicsSwimlanes({ state, commit, dispatch }, { withLists = true, endCursor = null }) {
    const { endpoints, boardType, filterParams } = state;
    const { fullPath, boardId } = endpoints;

    const variables = {
      fullPath,
      boardId: `gid://gitlab/Board/${boardId}`,
      issueFilters: filterParams,
      withLists,
      isGroup: boardType === BoardType.group,
      isProject: boardType === BoardType.project,
      after: endCursor,
    };

    return gqlClient
      .query({
        query: epicsSwimlanesQuery,
        variables,
      })
      .then(({ data }) => {
        const { epics, lists } = data[boardType]?.board;
        const epicsFormatted = epics.edges.map(e => ({
          ...e.node,
        }));

        if (!withLists) {
          commit(types.RECEIVE_EPICS_SUCCESS, epicsFormatted);
        } else {
          if (lists) {
            commit(types.RECEIVE_BOARD_LISTS_SUCCESS, formatBoardLists(lists));
          }

          if (epicsFormatted) {
            commit(types.RECEIVE_FIRST_EPICS_SUCCESS, {
              epics: epicsFormatted,
              canAdminEpic: epics.edges[0]?.node?.userPermissions?.adminEpic,
            });
          }
        }

        if (epics.pageInfo?.hasNextPage) {
          dispatch('fetchEpicsSwimlanes', {
            withLists: false,
            endCursor: epics.pageInfo.endCursor,
          });
        }
      })
      .catch(() => commit(types.RECEIVE_SWIMLANES_FAILURE));
  },

  updateBoardEpicUserPreferences({ commit, state }, { epicId, collapsed }) {
    const {
      endpoints: { boardId },
    } = state;

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

        const { epicUserPreferences: userPreferences } = data?.updateBoardEpicUserPreferences;
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

  updateListWipLimit({ state }, { maxIssueCount }) {
    const { activeId } = state;

    return axios.put(`${boardsStoreEE.store.state.endpoints.listsEndpoint}/${activeId}`, {
      list: {
        max_issue_count: maxIssueCount,
      },
    });
  },

  showPromotionList: ({ state, dispatch }) => {
    if (
      !state.showPromotion ||
      parseBoolean(Cookies.get('promotion_issue_board_hidden')) ||
      state.disabled
    ) {
      return;
    }
    dispatch('addList', {
      id: 'promotion',
      listType: ListType.promotion,
      title: __('Improve Issue Boards'),
      position: 0,
    });
  },

  fetchAllBoards: () => {
    notImplemented();
  },

  fetchRecentBoards: () => {
    notImplemented();
  },

  createBoard: () => {
    notImplemented();
  },

  deleteBoard: () => {
    notImplemented();
  },

  updateIssueWeight: () => {
    notImplemented();
  },

  togglePromotionState: () => {
    notImplemented();
  },

  fetchIssuesForList: ({ state, commit }, { listId, fetchNext = false, noEpicIssues = false }) => {
    commit(types.REQUEST_ISSUES_FOR_LIST, { listId, fetchNext });

    const { filterParams } = state;

    const variables = {
      id: listId,
      filters: noEpicIssues
        ? { ...filterParams, epicWildcardId: EpicFilterType.none.toUpperCase() }
        : filterParams,
      after: fetchNext ? state.pageInfoByListId[listId].endCursor : undefined,
      first: 20,
    };

    return fetchAndFormatListIssues(state, variables)
      .then(({ listIssues, listPageInfo }) => {
        commit(types.RECEIVE_ISSUES_FOR_LIST_SUCCESS, {
          listIssues,
          listPageInfo,
          listId,
          noEpicIssues,
        });
      })
      .catch(() => commit(types.RECEIVE_ISSUES_FOR_LIST_FAILURE, listId));
  },

  fetchIssuesForEpic: ({ state, commit }, epicId) => {
    commit(types.REQUEST_ISSUES_FOR_EPIC, epicId);

    const { filterParams } = state;

    const variables = {
      filters: { ...filterParams, epicId },
    };

    return fetchAndFormatListIssues(state, variables)
      .then(({ listIssues }) => {
        commit(types.RECEIVE_ISSUES_FOR_EPIC_SUCCESS, { ...listIssues, epicId });
      })
      .catch(() => commit(types.RECEIVE_ISSUES_FOR_EPIC_FAILURE, epicId));
  },

  toggleEpicSwimlanes: ({ state, commit, dispatch }) => {
    commit(types.TOGGLE_EPICS_SWIMLANES);

    if (state.isShowingEpicsSwimlanes) {
      dispatch('fetchEpicsSwimlanes', {}).catch(() => commit(types.RECEIVE_SWIMLANES_FAILURE));
    } else if (!gon.features.graphqlBoardLists) {
      boardsStore.create();
      eventHub.$emit('initialBoardLoad');
    }
  },

  resetEpics: ({ commit }) => {
    commit(types.RESET_EPICS);
  },

  setActiveIssueEpic: async ({ getters }, input) => {
    const { data } = await gqlClient.mutate({
      mutation: issueSetEpic,
      variables: {
        input: {
          iid: String(getters.getActiveIssue.iid),
          epicId: input.epicId,
          projectPath: input.projectPath,
        },
      },
    });

    if (data.issueSetEpic.errors?.length > 0) {
      throw new Error(data.issueSetEpic.errors);
    }

    return data.issueSetEpic.issue.epic;
  },

  moveIssue: (
    { state, commit },
    { issueId, issueIid, issuePath, fromListId, toListId, moveBeforeId, moveAfterId, epicId },
  ) => {
    const originalIssue = state.issues[issueId];
    const fromList = state.issuesByListId[fromListId];
    const originalIndex = fromList.indexOf(Number(issueId));
    commit(types.MOVE_ISSUE, {
      originalIssue,
      fromListId,
      toListId,
      moveBeforeId,
      moveAfterId,
      epicId,
    });

    const { boardId } = state.endpoints;
    const [fullProjectPath] = issuePath.split(/[#]/);

    gqlClient
      .mutate({
        mutation: issueMoveListMutation,
        variables: {
          projectPath: fullProjectPath,
          boardId: fullBoardId(boardId),
          iid: issueIid,
          fromListId: getIdFromGraphQLId(fromListId),
          toListId: getIdFromGraphQLId(toListId),
          moveBeforeId,
          moveAfterId,
          epicId,
        },
      })
      .then(({ data }) => {
        if (data?.issueMoveList?.errors.length) {
          commit(types.MOVE_ISSUE_FAILURE, { originalIssue, fromListId, toListId, originalIndex });
        } else {
          const issue = data.issueMoveList?.issue;
          commit(types.MOVE_ISSUE_SUCCESS, { issue });
        }
      })
      .catch(() =>
        commit(types.MOVE_ISSUE_FAILURE, { originalIssue, fromListId, toListId, originalIndex }),
      );
  },
};
