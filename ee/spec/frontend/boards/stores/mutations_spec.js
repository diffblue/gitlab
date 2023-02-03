import * as types from 'ee/boards/stores/mutation_types';
import mutations from 'ee/boards/stores/mutations';
import { mockEpics, mockEpic, mockLists, mockIssue, mockIssue2, mockSubGroups } from '../mock_data';

const initialBoardListsState = {
  'gid://gitlab/List/1': mockLists[0],
  'gid://gitlab/List/2': mockLists[1],
};

const epicId = mockEpic.id;

let state = {
  boardItemsByListId: {},
  boardItems: {},
  boardLists: initialBoardListsState,
  epicsFlags: {
    [epicId]: { isLoading: true },
  },
  subGroupsFlags: {
    isLoading: false,
    isLoadingMore: false,
    pageInfo: {},
  },
  fullBoardIssuesCount: {},
};

describe('SET_SHOW_LABELS', () => {
  it('updates isShowingLabels', () => {
    state = {
      ...state,
      isShowingLabels: true,
    };

    mutations.SET_SHOW_LABELS(state, false);

    expect(state.isShowingLabels).toBe(false);
  });
});

describe('REQUEST_ISSUES_FOR_EPIC', () => {
  it('sets isLoading epicsFlags in state for epicId to true', () => {
    state = {
      ...state,
      epicsFlags: {
        [epicId]: { isLoading: false },
      },
    };

    mutations.REQUEST_ISSUES_FOR_EPIC(state, epicId);

    expect(state.epicsFlags[epicId].isLoading).toBe(true);
  });
});

describe('RECEIVE_ISSUES_FOR_EPIC_SUCCESS', () => {
  it('sets boardItemsByListId and issues state for epic issues and loading state to false', () => {
    const listIssues = {
      'gid://gitlab/List/1': [mockIssue.id],
      'gid://gitlab/List/2': [mockIssue2.id],
    };
    const issues = {
      436: mockIssue,
      437: mockIssue2,
    };

    mutations.RECEIVE_ISSUES_FOR_EPIC_SUCCESS(state, {
      listData: listIssues,
      boardItems: issues,
      epicId,
    });

    expect(state.boardItemsByListId).toEqual(listIssues);
    expect(state.boardItems).toEqual(issues);
    expect(state.epicsFlags[epicId].isLoading).toBe(false);
  });
});

describe('RECEIVE_ISSUES_FOR_EPIC_FAILURE', () => {
  it('sets loading state to false for epic and error message', () => {
    mutations.RECEIVE_ISSUES_FOR_EPIC_FAILURE(state, epicId);

    expect(state.error).toEqual('An error occurred while fetching issues. Please reload the page.');
    expect(state.epicsFlags[epicId].isLoading).toBe(false);
  });
});

describe('TOGGLE_EPICS_SWIMLANES', () => {
  it('toggles isShowingEpicsSwimlanes from true to false', () => {
    state = {
      ...state,
      isShowingEpicsSwimlanes: true,
    };

    mutations.TOGGLE_EPICS_SWIMLANES(state);

    expect(state.isShowingEpicsSwimlanes).toBe(false);
  });

  it('toggles isShowingEpicsSwimlanes from false to true', () => {
    state = {
      ...state,
      isShowingEpicsSwimlanes: false,
    };

    mutations.TOGGLE_EPICS_SWIMLANES(state);

    expect(state.isShowingEpicsSwimlanes).toBe(true);
  });

  it('sets epicsSwimlanesFetchInProgress to true', () => {
    state = {
      ...state,
      epicsSwimlanesFetchInProgress: {
        epicLanesFetchInProgress: false,
        listItemsFetchInProgress: false,
      },
    };

    mutations.TOGGLE_EPICS_SWIMLANES(state);

    expect(state.epicsSwimlanesFetchInProgress).toEqual({
      epicLanesFetchInProgress: true,
      listItemsFetchInProgress: true,
    });
  });
});

describe('SET_EPICS_SWIMLANES', () => {
  it('set isShowingEpicsSwimlanes and epicsSwimlanesFetchInProgress to true', () => {
    state = {
      ...state,
      isShowingEpicsSwimlanes: false,
      epicsSwimlanesFetchInProgress: {
        epicLanesFetchInProgress: false,
        listItemsFetchInProgress: false,
      },
    };

    mutations.SET_EPICS_SWIMLANES(state);

    expect(state.isShowingEpicsSwimlanes).toBe(true);
    expect(state.epicsSwimlanesFetchInProgress).toEqual({
      epicLanesFetchInProgress: true,
      listItemsFetchInProgress: true,
    });
  });
});

describe('DONE_LOADING_SWIMLANES_ITEMS', () => {
  it('set listItemsFetchInProgress to false ans resets error', () => {
    state = {
      ...state,
      epicsSwimlanesFetchInProgress: {
        listItemsFetchInProgress: true,
      },
      error: 'Houston, we have a problem.',
    };

    mutations.DONE_LOADING_SWIMLANES_ITEMS(state);

    expect(state.epicsSwimlanesFetchInProgress.listItemsFetchInProgress).toBe(false);
    expect(state.error).toBe(undefined);
  });
});

describe('RECEIVE_BOARD_LISTS_SUCCESS', () => {
  it('populates boardLists with payload', () => {
    state = {
      ...state,
      boardLists: {},
    };

    mutations.RECEIVE_BOARD_LISTS_SUCCESS(state, initialBoardListsState);

    expect(state.boardLists).toEqual(initialBoardListsState);
  });
});

describe('RECEIVE_SWIMLANES_FAILURE', () => {
  it('sets epicLanesFetchInProgress to false and sets error message', () => {
    state = {
      ...state,
      epicsSwimlanesFetchInProgress: {
        epicLanesFetchInProgress: true,
      },
      error: undefined,
    };

    mutations.RECEIVE_SWIMLANES_FAILURE(state);

    expect(state.epicsSwimlanesFetchInProgress.epicLanesFetchInProgress).toBe(false);
    expect(state.error).toEqual(
      'An error occurred while fetching the board swimlanes. Please reload the page.',
    );
  });
});

describe('REQUEST_MORE_EPICS', () => {
  it('sets epicLanesFetchMoreInProgress to true', () => {
    state = {
      ...state,
      epicsSwimlanesFetchInProgress: {
        epicLanesFetchMoreInProgress: false,
      },
    };

    mutations.REQUEST_MORE_EPICS(state);

    expect(state.epicsSwimlanesFetchInProgress.epicLanesFetchMoreInProgress).toBe(true);
  });
});

describe('RECEIVE_EPICS_SUCCESS', () => {
  it('populates epics and canAdminEpic with payload', () => {
    state = {
      ...state,
      epics: {},
      canAdminEpic: false,
    };

    mutations.RECEIVE_EPICS_SUCCESS(state, { epics: mockEpics, canAdminEpic: true });

    expect(state.epics).toEqual(mockEpics);
    expect(state.canAdminEpic).toEqual(true);
  });

  it('merges epics while avoiding duplicates', () => {
    state = {
      ...state,
      epics: mockEpics,
      canAdminEpic: false,
    };

    mutations.RECEIVE_EPICS_SUCCESS(state, mockEpics);

    expect(state.epics).toEqual(mockEpics);
  });
});

describe('RESET_EPICS', () => {
  it('should remove issues from boardItemsByListId state', () => {
    state = {
      ...state,
      epics: mockEpics,
    };

    mutations.RESET_EPICS(state);

    expect(state.epics).toEqual([]);
  });
});

describe('MOVE_EPIC', () => {
  it('updates boardItemsByListId, moving epic between lists', () => {
    const listIssues = {
      'gid://gitlab/List/1': [mockEpic.id, mockEpics[1].id],
      'gid://gitlab/List/2': [],
    };

    const epics = {
      1: mockEpic,
      2: mockEpics[1],
    };

    state = {
      ...state,
      boardItemsByListId: listIssues,
      boardLists: initialBoardListsState,
      boardItems: epics,
    };

    mutations.MOVE_EPIC(state, {
      originalEpic: mockEpics[1],
      fromListId: 'gid://gitlab/List/1',
      toListId: 'gid://gitlab/List/2',
    });

    const updatedListEpics = {
      'gid://gitlab/List/1': [mockEpic.id],
      'gid://gitlab/List/2': [mockEpics[1].id],
    };

    expect(state.boardItemsByListId).toEqual(updatedListEpics);
  });
});

describe('SET_BOARD_EPIC_USER_PREFERENCES', () => {
  it('should replace userPreferences on the given epic', () => {
    state = {
      ...state,
      epics: mockEpics,
    };

    const epic = mockEpics[0];
    const userPreferences = { collapsed: false };

    mutations.SET_BOARD_EPIC_USER_PREFERENCES(state, { epicId: epic.id, userPreferences });

    expect(state.epics[0].userPreferences).toEqual(userPreferences);
  });
});

describe('REQUEST_SUB_GROUPS', () => {
  it('Should set isLoading in subGroupsFlags to true in state when fetchNext is false', () => {
    mutations[types.REQUEST_SUB_GROUPS](state, false);

    expect(state.subGroupsFlags.isLoading).toBe(true);
  });

  it('Should set isLoadingMore in subGroupsFlags to true in state when fetchNext is true', () => {
    mutations[types.REQUEST_SUB_GROUPS](state, true);

    expect(state.subGroupsFlags.isLoadingMore).toBe(true);
  });
});

describe('RECEIVE_SUB_GROUPS_SUCCESS', () => {
  it('Should set subGroups and pageInfo to state and isLoading in subGroupsFlags to false', () => {
    mutations[types.RECEIVE_SUB_GROUPS_SUCCESS](state, {
      subGroups: mockSubGroups,
      pageInfo: { hasNextPage: false },
    });

    expect(state.subGroups).toEqual(mockSubGroups);
    expect(state.subGroupsFlags.isLoading).toBe(false);
    expect(state.subGroupsFlags.pageInfo).toEqual({ hasNextPage: false });
  });

  it('Should merge groups in subGroups in state when fetchNext is true', () => {
    state = {
      ...state,
      subGroups: [mockSubGroups[0]],
    };

    mutations[types.RECEIVE_SUB_GROUPS_SUCCESS](state, {
      subGroups: [mockSubGroups[1]],
      fetchNext: true,
    });

    expect(state.subGroups).toEqual([mockSubGroups[0], mockSubGroups[1]]);
  });
});

describe('RECEIVE_SUB_GROUPS_FAILURE', () => {
  it('Should set error in state and isLoading in subGroupsFlags to false', () => {
    mutations[types.RECEIVE_SUB_GROUPS_FAILURE](state);

    expect(state.error).toEqual('An error occurred while fetching child groups. Please try again.');
    expect(state.subGroupsFlags.isLoading).toBe(false);
  });
});

describe('SET_SELECTED_GROUP', () => {
  it('Should set selectedGroup to state', () => {
    mutations[types.SET_SELECTED_GROUP](state, mockSubGroups[0]);

    expect(state.selectedGroup).toEqual(mockSubGroups[0]);
  });
});

describe('UPDATE_FULL_BOARD_ISSUES_COUNT', () => {
  const listId = 'gid://gitlab/List/1';
  const count = 20;
  it('Should set fullBoardIssuesCount to state', () => {
    mutations[types.UPDATE_FULL_BOARD_ISSUES_COUNT](state, { listId, count });

    expect(state.fullBoardIssuesCount[listId]).toEqual(count);
  });
});
