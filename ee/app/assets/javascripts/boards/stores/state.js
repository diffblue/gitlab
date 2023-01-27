import createStateCE from '~/boards/stores/state';

export default () => ({
  ...createStateCE(),

  allowSubEpics: false,
  canAdminEpic: false,
  isShowingEpicsSwimlanes: false,
  epicsSwimlanesFetchInProgress: {
    epicLanesFetchInProgress: false,
    listItemsFetchInProgress: false,
    epicLanesFetchMoreInProgress: false,
  },
  hasMoreEpics: false,
  epicsEndCursor: null,
  epics: [],
  epicsFlags: {},
  assignees: [],
  assigneesLoading: false,
  selectedGroup: {},
  subGroups: [],
  subGroupsFlags: {
    isLoading: false,
    isLoadingMore: false,
    pageInfo: {},
  },
  fullBoardIssuesCount: {},
});
