import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import Vuex from 'vuex';
import { IterationIDs } from 'ee/boards/constants';
import epicCreateMutation from 'ee/boards/graphql/epic_create.mutation.graphql';
import searchIterationCadencesQuery from 'ee/issues/list/queries/search_iteration_cadences.query.graphql';
import currentIterationQuery from 'ee/boards/graphql/board_current_iteration.query.graphql';
import actions, { gqlClient } from 'ee/boards/stores/actions';
import * as types from 'ee/boards/stores/mutation_types';
import mutations from 'ee/boards/stores/mutations';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { mockMoveIssueParams, mockMoveData, mockMoveState } from 'jest/boards/mock_data';
import { formatListIssues } from '~/boards/boards_util';
import { formatIssueInput } from 'ee_else_ce/boards/boards_util';
import listsIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import issueCreateMutation from '~/boards/graphql/issue_create.mutation.graphql';
import * as typesCE from '~/boards/stores/mutation_types';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_EPIC, TYPE_ISSUE, WORKSPACE_GROUP } from '~/issues/constants';
import { fetchPolicies } from '~/lib/graphql';
import * as commonUtils from '~/lib/utils/common_utils';
import { mergeUrlParams, removeParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  color,
  labels,
  mockEpicBoard,
  mockLists,
  mockIssue,
  mockIssues,
  mockEpic,
  mockIterations,
  mockAssignees,
  mockSubGroups,
  mockGroup0,
  mockIterationCadences,
  mockIssueInListWithIteration,
  mockListWithIteration,
  mockIssue3,
} from '../mock_data';

Vue.use(Vuex);

let mock;

beforeEach(() => {
  setWindowLocation(TEST_HOST);
  mock = new MockAdapter(axios);
  window.gon = { features: {} };
  jest.spyOn(commonUtils, 'historyPushState');
});

afterEach(() => {
  mock.restore();
});

describe('fetchEpicBoard', () => {
  const payload = {
    fullPath: 'gitlab-org',
    fullBoardId: 'gid://gitlab/Board::EpicBoard/1',
  };

  const queryResponse = {
    data: {
      workspace: {
        board: mockEpicBoard,
      },
    },
  };

  it('should commit mutation RECEIVE_BOARD_SUCCESS and dispatch setBoardConfig and performSearch on success', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    await testAction({
      action: actions.fetchEpicBoard,
      payload,
      expectedMutations: [{ type: types.REQUEST_CURRENT_BOARD }],
      expectedActions: [{ type: 'setBoard', payload: mockEpicBoard }, { type: 'fetchLists' }],
    });
  });

  it('should commit mutation RECEIVE_BOARD_FAILURE on failure', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    await testAction({
      action: actions.fetchBoard,
      payload,
      expectedMutations: [
        { type: types.REQUEST_CURRENT_BOARD },
        {
          type: types.RECEIVE_BOARD_FAILURE,
        },
      ],
    });
  });
});

describe('setFilters', () => {
  let state;

  beforeEach(() => {
    state = {
      filters: {},
      issuableType: TYPE_ISSUE,
    };
  });

  it.each([
    [
      'with correct EE filters as payload',
      {
        filters: { weight: 3, 'not[iterationId]': '1' },
        filterVariables: {
          weight: 3,
          not: {
            iterationId: 'gid://gitlab/Iteration/1',
          },
        },
      },
    ],
    [
      'and update epicId with global id',
      {
        filters: { epicId: 1 },
        filterVariables: { epicId: 'gid://gitlab/Epic/1', not: {} },
      },
    ],
    [
      "and use 'epicWildcardId' as filter variable when epic wildcard is used",
      {
        filters: { epicId: 'None' },
        filterVariables: { epicWildcardId: 'NONE', not: {} },
      },
    ],
    [
      "and use 'iterationWildcardId' as filter variable when iteration wildcard is used",
      {
        filters: { iterationId: 'None' },
        filterVariables: { iterationWildcardId: 'NONE', not: {} },
      },
    ],
    [
      "and use 'healthStatusFilter' as filter variable when health status is used",
      {
        filters: { healthStatus: 'NONE' },
        filterVariables: { healthStatusFilter: 'NONE', not: {} },
      },
    ],
  ])('should commit mutation SET_FILTERS %s', (_, { filters, filterVariables }) => {
    testAction(
      actions.setFilters,
      filters,
      state,
      [{ type: types.SET_FILTERS, payload: filterVariables }],
      [],
    );
  });

  it('should commit mutation SET_FILTERS, dispatches setEpicSwimlanes action if filters contain groupBy epic', () => {
    const filters = { labelName: 'label', epicId: 1, groupBy: 'epic' };
    const updatedFilters = { labelName: 'label', epicId: 'gid://gitlab/Epic/1', not: {} };

    return testAction(
      actions.setFilters,
      filters,
      state,
      [{ type: types.SET_FILTERS, payload: updatedFilters }],
      [{ type: 'setEpicSwimlanes' }],
    );
  });
});

describe('performSearch', () => {
  it('should dispatch setFilters, fetchLists and resetIssues action', async () => {
    const getters = { isSwimlanesOn: false };

    await testAction({
      action: actions.performSearch,
      state: { ...getters },
      expectedActions: [
        { type: 'setFilters', payload: {} },
        { type: 'fetchLists', payload: { resetLists: false } },
        { type: 'resetIssues' },
      ],
    });
  });

  it('should dispatch setFilters, resetEpics, fetchEpicsSwimlanes, fetchLists and resetIssues action when isSwimlanesOn', async () => {
    const getters = { isSwimlanesOn: true };
    await testAction({
      action: actions.performSearch,
      state: { isShowingEpicsSwimlanes: true, ...getters },
      expectedActions: [
        { type: 'setFilters', payload: {} },
        { type: 'resetEpics' },
        { type: 'fetchEpicsSwimlanes' },
        { type: 'fetchLists', payload: { resetLists: false } },
        { type: 'resetIssues' },
      ],
    });
  });
});

describe('fetchLists', () => {
  const queryResponse = {
    data: {
      group: {
        board: {
          hideBacklogList: true,
          lists: {
            nodes: [mockLists[1]],
          },
        },
      },
    },
  };

  it.each`
    issuableType | boardType          | fullBoardId                           | isGroup      | isProject
    ${TYPE_EPIC} | ${WORKSPACE_GROUP} | ${'gid://gitlab/Boards::EpicBoard/1'} | ${undefined} | ${undefined}
  `(
    'calls $issuableType query with correct variables',
    async ({ issuableType, boardType, fullBoardId, isGroup, isProject }) => {
      const commit = jest.fn();
      const dispatch = jest.fn();

      const state = {
        fullPath: 'gitlab-org',
        fullBoardId,
        filterParams: {},
        boardType,
        issuableType,
      };

      const variables = {
        fullPath: 'gitlab-org',
        boardId: fullBoardId,
        filters: {},
        isGroup,
        isProject,
      };

      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      await actions.fetchLists({ commit, state, dispatch });

      expect(gqlClient.query).toHaveBeenCalledWith(expect.objectContaining({ variables }));
    },
  );
});

describe('fetchEpicsSwimlanes', () => {
  const state = {
    fullPath: 'gitlab-org',
    boardId: 1,
    filterParams: {},
    boardType: 'group',
  };

  const queryResponse = {
    data: {
      group: {
        board: {
          epics: {
            nodes: [mockEpic],
            pageInfo: {},
          },
        },
      },
    },
  };

  const queryResponseWithNextPage = {
    data: {
      group: {
        board: {
          epics: {
            nodes: [mockEpic],
            pageInfo: {
              hasNextPage: true,
              endCursor: 'ENDCURSOR',
            },
          },
        },
      },
    },
  };

  it('should commit mutation RECEIVE_EPICS_SUCCESS on success', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    await testAction(
      actions.fetchEpicsSwimlanes,
      {},
      state,
      [
        {
          type: types.RECEIVE_EPICS_SUCCESS,
          payload: { epics: [mockEpic] },
        },
      ],
      [],
    );
  });

  it('should commit mutation REQUEST_MORE_EPICS when fetchNext is true', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    await testAction(
      actions.fetchEpicsSwimlanes,
      { fetchNext: true },
      state,
      [
        { type: types.REQUEST_MORE_EPICS },
        {
          type: types.RECEIVE_EPICS_SUCCESS,
          payload: { epics: [mockEpic] },
        },
      ],
      [],
    );
  });

  it('should commit mutation RECEIVE_EPICS_SUCCESS on success with hasMoreEpics when hasNextPage', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponseWithNextPage);

    await testAction(
      actions.fetchEpicsSwimlanes,
      {},
      state,
      [
        {
          type: types.RECEIVE_EPICS_SUCCESS,
          payload: {
            epics: [mockEpic],
            hasMoreEpics: true,
            epicsEndCursor: 'ENDCURSOR',
          },
        },
      ],
      [],
    );
  });

  it('should commit mutation RECEIVE_SWIMLANES_FAILURE on failure', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    await testAction(
      actions.fetchEpicsSwimlanes,
      {},
      state,
      [{ type: types.RECEIVE_SWIMLANES_FAILURE }],
      [],
    );
  });
});

describe('fetchItemsForList', () => {
  const listId = mockLists[0].id;

  let state = {
    fullPath: 'gitlab-org',
    boardId: '1',
    filterParams: {},
    boardType: 'group',
  };

  const mockIssuesNodes = mockIssues.map((issue) => ({ node: issue }));

  const pageInfo = {
    endCursor: '',
    hasNextPage: false,
  };

  const queryResponse = {
    data: {
      group: {
        board: {
          lists: {
            nodes: [
              {
                id: listId,
                issues: {
                  edges: mockIssuesNodes,
                  pageInfo,
                },
              },
            ],
          },
        },
      },
    },
  };

  const formattedIssues = formatListIssues(queryResponse.data.group.board.lists);

  const listPageInfo = {
    [listId]: pageInfo,
  };

  describe('when listId is undefined', () => {
    it('does not call the query', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      await actions.fetchItemsForList(
        { state, getters: () => {}, commit: () => {} },
        { listId: undefined },
      );

      expect(gqlClient.query).toHaveBeenCalledTimes(0);
    });
  });

  it('add epicWildcardId with NONE as value when noEpicIssues is true', async () => {
    state = {
      ...state,
      isShowingEpicsSwimlanes: true,
    };
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    await testAction(
      actions.fetchItemsForList,
      { listId, noEpicIssues: true },
      state,
      [
        {
          type: types.REQUEST_ITEMS_FOR_LIST,
          payload: { listId, fetchNext: false },
        },
        {
          type: types.RECEIVE_ITEMS_FOR_LIST_SUCCESS,
          payload: { listItems: formattedIssues, listPageInfo, listId, noEpicIssues: true },
        },
      ],
      [],
    );
    expect(gqlClient.query).toHaveBeenCalledWith({
      query: listsIssuesQuery,
      variables: {
        boardId: 'gid://gitlab/Board/1',
        filters: {
          epicWildcardId: 'NONE',
        },
        fullPath: 'gitlab-org',
        id: 'gid://gitlab/List/1',
        isGroup: true,
        isProject: false,
        after: undefined,
        first: 10,
      },
      fetchPolicy: fetchPolicies.NO_CACHE,
      context: {
        isSingleRequest: true,
      },
    });
  });
});

describe('updateBoardEpicUserPreferences', () => {
  const state = {
    boardId: 1,
  };

  const queryResponse = (collapsed = false) => ({
    data: {
      updateBoardEpicUserPreferences: {
        errors: [],
        epicUserPreferences: { collapsed },
      },
    },
  });

  it('should send mutation', async () => {
    const collapsed = true;
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue(queryResponse(collapsed));

    await testAction(
      actions.updateBoardEpicUserPreferences,
      { epicId: mockEpic.id, collapsed },
      state,
      [
        {
          payload: {
            epicId: mockEpic.id,
            userPreferences: {
              collapsed,
            },
          },
          type: types.SET_BOARD_EPIC_USER_PREFERENCES,
        },
      ],
      [],
    );
  });
});

describe('setShowLabels', () => {
  it('should commit mutation SET_SHOW_LABELS', async () => {
    const state = {
      isShowingLabels: true,
    };

    await testAction(
      actions.setShowLabels,
      false,
      state,
      [{ type: types.SET_SHOW_LABELS, payload: false }],
      [],
    );
  });
});

describe('updateListWipLimit', () => {
  beforeEach(() => {
    jest.mock('axios');
    axios.put = jest.fn();
    axios.put.mockResolvedValue({ data: {} });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('commit UPDATE_LIST_SUCCESS mutation on success', () => {
    const maxIssueCount = 0;
    const activeId = 1;
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        boardListUpdateLimitMetrics: {
          list: {
            id: activeId,
          },
          errors: [],
        },
      },
    });

    return testAction(
      actions.updateListWipLimit,
      { maxIssueCount, listId: activeId },
      { isShowingEpicsSwimlanes: true },
      [
        {
          type: types.UPDATE_LIST_SUCCESS,
          payload: {
            listId: activeId,
            list: expect.objectContaining({
              id: activeId,
            }),
          },
        },
      ],
      [],
    );
  });

  it('dispatch handleUpdateListFailure on failure', () => {
    const maxIssueCount = 0;
    const activeId = 1;
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue(Promise.reject());

    return testAction(
      actions.updateListWipLimit,
      { maxIssueCount, listId: activeId },
      { isShowingEpicsSwimlanes: true },
      [],
      [{ type: 'handleUpdateListFailure' }],
    );
  });
});

describe('fetchIssuesForEpic', () => {
  const listId = mockLists[0].id;
  const epicId = mockEpic.id;

  const state = {
    fullPath: 'gitlab-org',
    boardId: 1,
    filterParams: {},
    boardType: 'group',
  };

  const queryResponse = {
    data: {
      group: {
        board: {
          lists: {
            nodes: [
              {
                id: listId,
                issues: {
                  edges: [{ node: [mockIssue] }],
                },
              },
            ],
          },
        },
      },
    },
  };

  const formattedIssues = formatListIssues(queryResponse.data.group.board.lists);

  it('should commit mutations REQUEST_ISSUES_FOR_EPIC and RECEIVE_ITEMS_FOR_LIST_SUCCESS on success', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    await testAction(
      actions.fetchIssuesForEpic,
      epicId,
      state,
      [
        { type: types.REQUEST_ISSUES_FOR_EPIC, payload: epicId },
        { type: types.RECEIVE_ISSUES_FOR_EPIC_SUCCESS, payload: { ...formattedIssues, epicId } },
      ],
      [],
    );
  });

  it('should commit mutations REQUEST_ISSUES_FOR_EPIC and RECEIVE_ITEMS_FOR_LIST_FAILURE on failure', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(Promise.reject());

    await testAction(
      actions.fetchIssuesForEpic,
      epicId,
      state,
      [
        { type: types.REQUEST_ISSUES_FOR_EPIC, payload: epicId },
        { type: types.RECEIVE_ISSUES_FOR_EPIC_FAILURE, payload: epicId },
      ],
      [],
    );
  });
});

describe('toggleEpicSwimlanes', () => {
  it('should commit mutation TOGGLE_EPICS_SWIMLANES', () => {
    const startURl = `${TEST_HOST}/groups/gitlab-org/-/boards/1?group_by=epic`;
    setWindowLocation(startURl);

    const state = {
      isShowingEpicsSwimlanes: false,
      fullPath: 'gitlab-org',
      boardId: 1,
    };

    return testAction(
      actions.toggleEpicSwimlanes,
      null,
      state,
      [{ type: types.TOGGLE_EPICS_SWIMLANES }],
      [],
      () => {
        expect(commonUtils.historyPushState).toHaveBeenCalledWith(
          removeParams(['group_by']),
          startURl,
          true,
        );
        expect(global.window.location.href).toBe(`${TEST_HOST}/groups/gitlab-org/-/boards/1`);
      },
    );
  });

  it('should dispatch fetchEpicsSwimlanes and fetchLists actions when isShowingEpicsSwimlanes is true', () => {
    setWindowLocation(`${TEST_HOST}/groups/gitlab-org/-/boards/1`);

    jest.spyOn(gqlClient, 'query').mockResolvedValue({});

    const state = {
      isShowingEpicsSwimlanes: true,
      fullPath: 'gitlab-org',
      boardId: 1,
    };

    return testAction(
      actions.toggleEpicSwimlanes,
      null,
      state,
      [{ type: types.TOGGLE_EPICS_SWIMLANES }],
      [{ type: 'fetchEpicsSwimlanes' }, { type: 'fetchLists' }],
      () => {
        expect(commonUtils.historyPushState).toHaveBeenCalledWith(
          mergeUrlParams({ group_by: TYPE_EPIC }, window.location.href),
        );
        expect(global.window.location.href).toBe(
          `${TEST_HOST}/groups/gitlab-org/-/boards/1?group_by=epic`,
        );
      },
    );
  });
});

describe('setEpicSwimlanes', () => {
  it('should commit mutation SET_EPICS_SWIMLANES', () => {
    return testAction(
      actions.setEpicSwimlanes,
      null,
      {},
      [{ type: types.SET_EPICS_SWIMLANES }],
      [],
    );
  });
});

describe('doneLoadingSwimlanesItems', () => {
  it('should commit mutation DONE_LOADING_SWIMLANES_ITEMS', () => {
    return testAction(
      actions.doneLoadingSwimlanesItems,
      null,
      {},
      [{ type: types.DONE_LOADING_SWIMLANES_ITEMS }],
      [],
    );
  });
});

describe('resetEpics', () => {
  it('commits RESET_EPICS mutation', () => {
    return testAction(actions.resetEpics, {}, {}, [{ type: types.RESET_EPICS }], []);
  });
});

describe('setActiveItemWeight', () => {
  const state = { boardItems: { [mockIssue.id]: mockIssue } };
  const getters = { activeBoardItem: mockIssue };
  const testWeight = mockIssue.weight + 1;
  const input = { weight: testWeight, id: mockIssue.id };

  it('should commit weight', async () => {
    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'weight',
      value: testWeight,
    };

    await testAction(
      actions.setActiveItemWeight,
      input,
      { ...state, ...getters },
      [
        {
          type: typesCE.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
    );
  });

  it('throws error if fails', async () => {
    jest
      .spyOn(gqlClient, 'mutate')
      .mockResolvedValue({ data: { issueSetWeight: { errors: ['failed mutation'] } } });

    await expect(actions.setActiveItemWeight({ getters }, input)).rejects.toThrow(Error);
  });
});

describe('setActiveItemHealthStatus', () => {
  it('should commit health status', () => {
    const payload = {
      itemId: mockIssue.id,
      prop: 'healthStatus',
      value: 'onTrack',
    };
    testAction(
      actions.setActiveItemHealthStatus,
      payload.value,
      { boardItems: { [mockIssue.id]: mockIssue }, activeBoardItem: mockIssue },
      [{ type: typesCE.UPDATE_BOARD_ITEM_BY_ID, payload }],
      [],
    );
  });
});

describe.each`
  isEpicBoard | issuableType  | dispatchedAction
  ${false}    | ${TYPE_ISSUE} | ${'moveIssue'}
  ${true}     | ${TYPE_EPIC}  | ${'moveEpic'}
`('moveItem', ({ isEpicBoard, issuableType, dispatchedAction }) => {
  it(`should dispatch ${dispatchedAction}  action when isEpicBoard is ${isEpicBoard}`, async () => {
    await testAction({
      action: actions.moveItem,
      payload: { itemId: 1 },
      state: { isEpicBoard, issuableType },
      expectedActions: [{ type: dispatchedAction, payload: { itemId: 1 } }],
    });
  });
});

describe('moveIssue', () => {
  it('should dispatch a correct set of actions with epic id', () => {
    const params = mockMoveIssueParams;

    const moveData = {
      ...mockMoveData,
      epicId: 'some-epic-id',
    };

    testAction({
      action: actions.moveIssue,
      payload: {
        ...params,
        epicId: 'some-epic-id',
      },
      state: mockMoveState,
      expectedActions: [
        { type: 'moveIssueCard', payload: moveData },
        { type: 'updateMovedIssue', payload: moveData },
        { type: 'updateEpicForIssue', payload: { itemId: params.itemId, epicId: 'some-epic-id' } },
        {
          type: 'updateIssueOrder',
          payload: {
            moveData,
            mutationVariables: {
              epicId: 'some-epic-id',
            },
          },
        },
      ],
    });
  });
});

describe('updateEpicForIssue', () => {
  let commonState;

  beforeEach(() => {
    commonState = {
      boardItems: {
        itemId: {
          id: 'issueId',
        },
      },
    };
  });

  it.each([
    [
      'with epic id',
      {
        payload: {
          itemId: 'itemId',
          epicId: 'epicId',
        },
        expectedMutations: [
          {
            type: types.UPDATE_BOARD_ITEM_BY_ID,
            payload: { itemId: 'issueId', prop: 'epic', value: { id: 'epicId' } },
          },
        ],
      },
    ],
    [
      'with null as epic id',
      {
        payload: {
          itemId: 'itemId',
          epicId: null,
        },
        expectedMutations: [
          {
            type: types.UPDATE_BOARD_ITEM_BY_ID,
            payload: { itemId: 'issueId', prop: 'epic', value: null },
          },
        ],
      },
    ],
  ])(`commits UPDATE_BOARD_ITEM_BY_ID mutation %s`, (_, { payload, expectedMutations }) => {
    testAction({
      action: actions.updateEpicForIssue,
      payload,
      state: commonState,
      expectedMutations,
    });
  });
});

describe.each`
  isEpicBoard | issuableType  | dispatchedAction
  ${false}    | ${TYPE_ISSUE} | ${'createIssueList'}
  ${true}     | ${TYPE_EPIC}  | ${'createEpicList'}
`('createList', ({ isEpicBoard, issuableType, dispatchedAction }) => {
  it(`should dispatch ${dispatchedAction}  action when isEpicBoard is ${isEpicBoard}`, async () => {
    await testAction({
      action: actions.createList,
      payload: { backlog: true },
      state: { isEpicBoard, issuableType },
      expectedActions: [{ type: dispatchedAction, payload: { backlog: true } }],
    });
  });
});

describe('createEpicList', () => {
  let commit;
  let dispatch;
  let getters;

  const state = {
    fullPath: 'gitlab-org',
    boardId: 1,
    boardType: 'group',
    disabled: false,
    boardLists: mockLists,
  };

  beforeEach(() => {
    commit = jest.fn();
    dispatch = jest.fn();
    getters = {
      getListByLabelId: jest.fn(),
    };
  });

  it('should dispatch addList action when creating backlog list', async () => {
    const backlogList = {
      id: 'gid://gitlab/List/1',
      listType: 'backlog',
      title: 'Open',
      position: 0,
    };

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        epicBoardListCreate: {
          list: backlogList,
          errors: [],
        },
      },
    });

    await actions.createEpicList({ getters, state, commit, dispatch }, { backlog: true });

    expect(dispatch).toHaveBeenCalledWith('addList', backlogList);
  });

  it('dispatches highlightList after addList has succeeded', async () => {
    const list = {
      id: 'gid://gitlab/List/1',
      listType: 'label',
      title: 'Open',
      labelId: '4',
    };

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        epicBoardListCreate: {
          list,
          errors: [],
        },
      },
    });

    await actions.createEpicList({ getters, state, commit, dispatch }, { labelId: '4' });

    expect(dispatch).toHaveBeenCalledWith('addList', list);
    expect(dispatch).toHaveBeenCalledWith('highlightList', list.id);
  });

  it('should commit CREATE_LIST_FAILURE mutation when API returns an error', async () => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        epicBoardListCreate: {
          list: {},
          errors: ['foo'],
        },
      },
    });

    await actions.createEpicList({ getters, state, commit, dispatch }, { backlog: true });

    expect(commit).toHaveBeenCalledWith(types.CREATE_LIST_FAILURE, 'foo');
  });

  it('highlights list and does not re-query if it already exists', async () => {
    const existingList = {
      id: 'gid://gitlab/List/1',
      listType: 'label',
      title: 'Some label',
      position: 1,
    };

    getters = {
      getListByLabelId: jest.fn().mockReturnValue(existingList),
    };

    await actions.createEpicList({ getters, state, commit, dispatch }, { backlog: true });

    expect(dispatch).toHaveBeenCalledWith('highlightList', existingList.id);
    expect(dispatch).toHaveBeenCalledTimes(1);
    expect(commit).not.toHaveBeenCalled();
  });
});

describe('addListNewEpic', () => {
  const state = {
    boardType: 'group',
    fullPath: 'gitlab-org/gitlab',
    boardConfig: {
      labelIds: ['gid://gitlab/GroupLabel/23'],
      assigneeId: null,
      milestoneId: -1,
    },
  };

  const fakeList = { id: 'gid://gitlab/List/123' };

  it('should add board scope to the epic being created', async () => {
    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        createEpic: {
          epic: mockEpic,
          errors: [],
        },
      },
    });

    await actions.addListNewEpic(
      { dispatch: jest.fn(), commit: jest.fn(), state },
      { epicInput: { ...mockEpic, groupPath: state.fullPath }, list: fakeList },
    );

    expect(gqlClient.mutate).toHaveBeenCalledWith({
      mutation: epicCreateMutation,
      variables: {
        input: {
          ...mockEpic,
          groupPath: state.fullPath,
          id: 'gid://gitlab/Epic/41',
          addLabelIds: [23],
        },
      },
    });
  });

  it('should add board scope by merging attributes to the epic being created', async () => {
    const epic = {
      ...mockEpic,
      labelIds: [4],
    };

    jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
      data: {
        createEpic: {
          epic,
          errors: [],
        },
      },
    });

    const payload = {
      ...mockEpic,
      addLabelIds: [...epic.labelIds, 23],
    };

    await actions.addListNewEpic(
      { dispatch: jest.fn(), commit: jest.fn(), state },
      { epicInput: { ...epic, groupPath: state.fullPath }, list: fakeList },
    );

    expect(gqlClient.mutate).toHaveBeenCalledWith({
      mutation: epicCreateMutation,
      variables: {
        input: {
          ...payload,
          groupPath: state.fullPath,
        },
      },
    });
    expect(payload.addLabelIds).toEqual([4, 23]);
  });

  describe('when issue creation mutation request succeeds', () => {
    it('dispatches a correct set of mutations', () => {
      jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
        data: {
          createEpic: {
            epic: mockEpic,
            errors: [],
          },
        },
      });

      testAction({
        action: actions.addListNewEpic,
        payload: {
          epicInput: mockEpic,
          list: fakeList,
          placeholderId: 'tmp',
        },
        state,
        expectedActions: [
          {
            type: 'addListItem',
            payload: {
              list: fakeList,
              item: { ...mockEpic, id: 'tmp', isLoading: true, labels: [], assignees: [] },
              position: 0,
              inProgress: true,
            },
          },
          { type: 'removeListItem', payload: { listId: fakeList.id, itemId: 'tmp' } },
          {
            type: 'addListItem',
            payload: {
              list: fakeList,
              item: { ...mockEpic, assignees: [] },
              position: 0,
            },
          },
        ],
      });
    });
  });

  describe('when issue creation mutation request fails', () => {
    it('dispatches a correct set of mutations', () => {
      jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
        data: {
          createEpic: {
            epic: mockEpic,
            errors: [{ foo: 'bar' }],
          },
        },
      });

      testAction({
        action: actions.addListNewEpic,
        payload: {
          epicInput: mockEpic,
          list: fakeList,
          placeholderId: 'tmp',
        },
        state,
        expectedActions: [
          {
            type: 'addListItem',
            payload: {
              list: fakeList,
              item: { ...mockEpic, id: 'tmp', isLoading: true, labels: [], assignees: [] },
              position: 0,
              inProgress: true,
            },
          },
          { type: 'removeListItem', payload: { listId: fakeList.id, itemId: 'tmp' } },
        ],
        expectedMutations: [
          {
            type: types.SET_ERROR,
            payload: 'An error occurred while creating the epic. Please try again.',
          },
        ],
      });
    });
  });
});

describe('fetchIterations', () => {
  const queryResponse = {
    data: {
      group: {
        iterations: {
          nodes: mockIterations,
        },
      },
    },
  };

  const queryErrors = {
    data: {
      group: {
        errors: ['You cannot view these iterations'],
        iterations: {},
      },
    },
  };

  function createStore({
    state = {
      boardType: 'group',
      fullPath: 'gitlab-org/gitlab',
      iterations: [],
      iterationsLoading: false,
    },
  } = {}) {
    return new Vuex.Store({
      state,
      mutations,
    });
  }

  it('sets iterationsLoading to true', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    const store = createStore();

    actions.fetchIterations(store);

    expect(store.state.iterationsLoading).toBe(true);
  });

  describe('success', () => {
    it('sets state.iterations from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      const store = createStore();

      await actions.fetchIterations(store);

      expect(store.state.iterationsLoading).toBe(false);
      expect(store.state.iterations).toBe(mockIterations);
    });
  });

  describe('failure', () => {
    it('throws an error and displays an error message', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryErrors);

      const store = createStore();

      await expect(actions.fetchIterations(store)).rejects.toThrow();

      expect(store.state.iterationsLoading).toBe(false);
      expect(store.state.error).toBe('Failed to load iterations.');
    });
  });
});

describe('fetchIterationCadences', () => {
  const queryResponse = {
    data: {
      group: {
        iterationCadences: {
          nodes: mockIterationCadences,
        },
      },
    },
  };

  const queryErrors = {
    data: {
      group: {
        errors: ['You cannot view these iteration cadences'],
        iterationCadences: {},
      },
    },
  };

  function createStore({
    state = {
      boardType: 'group',
      fullPath: 'gitlab-org/gitlab',
      iterationCadences: [],
      iterationCadencesLoading: false,
    },
  } = {}) {
    return new Vuex.Store({
      state,
      mutations,
    });
  }

  it('sets iterationCadencesLoading to true', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    const store = createStore();

    actions.fetchIterationCadences(store);

    expect(store.state.iterationCadencesLoading).toBe(true);
  });

  describe('success', () => {
    it('with search by title - sets state.iterationCadences from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      const store = createStore();

      await actions.fetchIterationCadences(store, 'search');

      expect(store.state.iterationCadencesLoading).toBe(false);
      expect(store.state.iterationCadences).toBe(mockIterationCadences);

      expect(gqlClient.query).toHaveBeenCalledWith({
        query: searchIterationCadencesQuery,
        variables: {
          fullPath: 'gitlab-org/gitlab',
          title: 'search',
          isProject: false,
        },
      });
    });

    it('with search by id - sets state.iterationCadences from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      const store = createStore();

      await actions.fetchIterationCadences(store, '11');

      expect(store.state.iterationCadencesLoading).toBe(false);
      expect(store.state.iterationCadences).toBe(mockIterationCadences);

      expect(gqlClient.query).toHaveBeenCalledWith({
        query: searchIterationCadencesQuery,
        variables: {
          fullPath: 'gitlab-org/gitlab',
          id: 'gid://gitlab/Iterations::Cadence/11',
          isProject: false,
        },
      });
    });
  });

  describe('failure', () => {
    it('throws an error and displays an error message', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryErrors);

      const store = createStore();

      await expect(actions.fetchIterationCadences(store)).rejects.toThrow();

      expect(store.state.iterationCadencesLoading).toBe(false);
      expect(store.state.error).toBe(__('Failed to load iteration cadences.'));
    });
  });
});

describe('fetchAssignees', () => {
  const queryResponse = {
    data: {
      workspace: {
        assignees: {
          nodes: mockAssignees.map((assignee) => ({ user: assignee })),
        },
      },
    },
  };

  const queryErrors = {
    data: {
      project: {
        errors: ['You cannot view these assignees'],
        assignees: {},
      },
    },
  };

  function createStore({
    state = {
      boardType: 'project',
      fullPath: 'gitlab-org/gitlab',
      assignees: [],
      assigneesLoading: false,
    },
  } = {}) {
    return new Vuex.Store({
      state,
      mutations,
    });
  }

  it('throws error if state.boardType is not group or project', () => {
    const store = createStore({
      state: {
        boardType: 'invalid',
      },
    });

    expect(() => actions.fetchAssignees(store)).toThrow(new Error('Unknown board type'));
  });

  it('sets assigneesLoading to true', () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    const store = createStore();

    actions.fetchAssignees(store);

    expect(store.state.assigneesLoading).toBe(true);
  });

  describe('success', () => {
    it('sets state.assignees from query result', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

      const store = createStore();

      await actions.fetchAssignees(store);

      expect(store.state.assigneesLoading).toBe(false);
      expect(store.state.assignees).toEqual(expect.objectContaining(mockAssignees));
    });
  });

  describe('failure', () => {
    it('throws an error and displays an error message', async () => {
      jest.spyOn(gqlClient, 'query').mockResolvedValue(queryErrors);

      const store = createStore();

      await expect(actions.fetchAssignees(store)).rejects.toThrow();

      expect(store.state.assigneesLoading).toBe(false);
      expect(store.state.error).toBe('Failed to load assignees.');
    });
  });
});

describe('fetchSubGroups', () => {
  const state = {
    fullPath: 'gitlab-org',
  };

  const pageInfo = {
    endCursor: '',
    hasNextPage: false,
  };

  const queryResponse = {
    data: {
      group: {
        descendantGroups: {
          nodes: mockSubGroups.slice(1), // First group is root group, so skip it.
          pageInfo: {
            endCursor: '',
            hasNextPage: false,
          },
        },
        ...mockGroup0, // Add root group info
      },
    },
  };

  it('should commit mutations REQUEST_SUB_GROUPS, RECEIVE_SUB_GROUPS_SUCCESS, and SET_SELECTED_GROUP on success', async () => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);

    await testAction(
      actions.fetchSubGroups,
      {},
      state,
      [
        {
          type: types.REQUEST_SUB_GROUPS,
          payload: false,
        },
        {
          type: types.RECEIVE_SUB_GROUPS_SUCCESS,
          payload: { subGroups: mockSubGroups, pageInfo, fetchNext: false },
        },
        {
          type: types.SET_SELECTED_GROUP,
          payload: mockGroup0,
        },
      ],
      [],
    );
  });

  it('should commit mutations REQUEST_SUB_GROUPS and RECEIVE_SUB_GROUPS_FAILURE on failure', async () => {
    jest.spyOn(gqlClient, 'query').mockRejectedValue();

    await testAction(
      actions.fetchSubGroups,
      {},
      state,
      [
        {
          type: types.REQUEST_SUB_GROUPS,
          payload: false,
        },
        {
          type: types.RECEIVE_SUB_GROUPS_FAILURE,
        },
      ],
      [],
    );
  });
});

describe('setSelectedGroup', () => {
  it('should commit mutation SET_SELECTED_GROUP', async () => {
    await testAction(
      actions.setSelectedGroup,
      mockGroup0,
      {},
      [
        {
          type: types.SET_SELECTED_GROUP,
          payload: mockGroup0,
        },
      ],
      [],
    );
  });
});

describe('setActiveEpicLabels', () => {
  const state = { boardItems: { [mockEpic.id]: mockEpic } };
  const getters = { activeBoardItem: { ...mockEpic, labels } };
  const testLabelIds = labels.map((label) => label.id);
  const input = {
    addLabelIds: testLabelIds,
    removeLabelIds: [],
    groupPath: 'h/b',
  };

  it('should assign labels', () => {
    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'labels',
      value: labels,
    };

    testAction(
      actions.setActiveEpicLabels,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
    );
  });

  it('should remove label', () => {
    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'labels',
      value: [labels[1]],
    };

    testAction(
      actions.setActiveEpicLabels,
      { ...input, removeLabelIds: [getIdFromGraphQLId(labels[0].id)] },
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
    );
  });
});

describe('addListNewIssue', () => {
  let state;
  let iterationCadenceId = 'gid://gitlab/Iterations::Cadence/1';
  const baseState = {
    boardType: 'group',
    fullPath: 'gitlab-org/gitlab',
    boardConfig: {
      labelIds: [],
    },
  };

  const queryResponse = {
    data: {
      group: {
        id: 'gid://gitlab/Group/1',
        iterations: {
          nodes: [
            {
              id: 'gid://gitlab/Iteration/1',
              iterationCadence: {
                id: iterationCadenceId,
              },
            },
          ],
        },
      },
    },
  };

  const fakeList = {};

  beforeEach(() => {
    jest.spyOn(gqlClient, 'query').mockResolvedValue(queryResponse);
  });

  describe('without cadenceId', () => {
    describe('currentIteration selected in board config', () => {
      beforeEach(() => {
        state = {
          ...baseState,
          boardConfig: {
            iterationId: IterationIDs.CURRENT,
          },
        };
      });

      it('adds iterationCadenceId from iteration', async () => {
        jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
          data: {
            createIssue: {
              errors: [],
            },
          },
        });

        await actions.addListNewIssue(
          { dispatch: jest.fn(), commit: jest.fn(), state },
          { issueInput: mockIssue, list: fakeList },
        );

        expect(gqlClient.query).toHaveBeenCalledWith({
          query: currentIterationQuery,
          variables: {
            fullPath: state.fullPath,
            isGroup: state.boardType === WORKSPACE_GROUP,
          },
          context: {
            isSingleRequest: true,
          },
        });

        expect(gqlClient.mutate).toHaveBeenCalledWith({
          mutation: issueCreateMutation,
          variables: {
            input: formatIssueInput(mockIssue, {
              ...state.boardConfig,
              iterationCadenceId,
            }),
          },
          update: expect.anything(),
        });
      });
    });

    describe('currentIteration not in boardConfig', () => {
      beforeEach(() => {
        state = {
          ...baseState,
          boardConfig: {
            iterationId: null,
          },
        };
      });

      it('does not add iterationCadenceId', async () => {
        jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
          data: {
            createIssue: {
              errors: [],
            },
          },
        });

        await actions.addListNewIssue(
          { dispatch: jest.fn(), commit: jest.fn(), state },
          { issueInput: mockIssue, list: fakeList },
        );

        expect(gqlClient.mutate).toHaveBeenCalledWith({
          mutation: issueCreateMutation,
          variables: {
            input: formatIssueInput(mockIssue, state.boardConfig),
          },
          update: expect.anything(),
        });
      });
    });
  });

  describe('with iterationCadenceId', () => {
    beforeEach(() => {
      state = {
        ...baseState,
        boardConfig: {
          iterationId: IterationIDs.CURRENT,
          iterationCadenceId,
        },
      };
    });

    it('does not make query for cadence of current iteration', async () => {
      jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
        data: {
          createIssue: {
            errors: [],
          },
        },
      });

      await actions.addListNewIssue(
        { dispatch: jest.fn(), commit: jest.fn(), state },
        { issueInput: mockIssue, list: fakeList },
      );

      expect(gqlClient.query).not.toHaveBeenCalled();
      expect(gqlClient.mutate).toHaveBeenCalledWith({
        mutation: issueCreateMutation,
        variables: {
          input: formatIssueInput(mockIssue, state.boardConfig),
        },
        update: expect.anything(),
      });
    });
  });

  describe('with listIterationId', () => {
    describe('list has an iteration', () => {
      beforeEach(() => {
        state = {
          ...baseState,
          boardConfig: {
            iterationId: mockListWithIteration.iteration.id,
          },
        };

        iterationCadenceId = null;
      });

      it('adds iterationId from list iteration', async () => {
        jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
          data: {
            createIssue: {
              errors: [],
            },
          },
        });

        await actions.addListNewIssue(
          { dispatch: jest.fn(), commit: jest.fn(), state },
          { issueInput: mockIssueInListWithIteration, list: mockListWithIteration },
        );

        expect(gqlClient.mutate).toHaveBeenCalledWith({
          mutation: issueCreateMutation,
          variables: {
            input: formatIssueInput(mockIssueInListWithIteration, {
              ...state.boardConfig,
              iterationCadenceId,
            }),
          },
          update: expect.anything(),
        });
      });
    });

    describe('neither list nor board has an iteration', () => {
      beforeEach(() => {
        state = {
          ...baseState,
          boardConfig: {
            iterationId: undefined,
          },
        };

        iterationCadenceId = null;
      });

      it('not adds any iteration', async () => {
        jest.spyOn(gqlClient, 'mutate').mockResolvedValue({
          data: {
            createIssue: {
              errors: [],
            },
          },
        });

        await actions.addListNewIssue(
          { dispatch: jest.fn(), commit: jest.fn(), state },
          { issueInput: mockIssue3, list: fakeList },
        );

        expect(gqlClient.mutate).toHaveBeenCalledWith({
          mutation: issueCreateMutation,
          variables: {
            input: formatIssueInput(mockIssue3, {
              ...state.boardConfig,
              iterationCadenceId,
            }),
          },
          update: expect.anything(),
        });
      });
    });
  });
});

describe('setActiveEpicColor', () => {
  const state = { boardItems: { [mockEpic.id]: mockEpic } };
  const getters = { activeBoardItem: { ...mockEpic, color } };
  const newColor = {
    color: '#00ff00',
    title: 'Green',
  };
  const input = {
    color: newColor,
    groupPath: 'h/b',
  };

  it('should change color', () => {
    const payload = {
      itemId: getters.activeBoardItem.id,
      prop: 'color',
      value: newColor.color,
    };

    testAction(
      actions.setActiveEpicColor,
      input,
      { ...state, ...getters },
      [
        {
          type: types.UPDATE_BOARD_ITEM_BY_ID,
          payload,
        },
      ],
      [],
    );
  });
});

describe('setFullBoardIssuesCount', () => {
  const payload = { listId: 'gid://gitlab/List/1', count: 2 };
  it('should commit mutation UPDATE_FULL_BOARD_ISSUES_COUNT', async () => {
    await testAction(
      actions.setFullBoardIssuesCount,
      payload,
      {},
      [
        {
          type: types.UPDATE_FULL_BOARD_ISSUES_COUNT,
          payload,
        },
      ],
      [],
    );
  });
});
