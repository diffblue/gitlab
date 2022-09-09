export default () => ({
  // Initial Data
  parentItem: {},
  epicsEndpoint: '',
  issuesEndpoint: '',
  projectsEndpoint: null,
  userSignedIn: false,

  children: {},
  childrenFlags: {},
  epicsCount: 0,
  issuesCount: 0,
  weightSum: {
    openedIssues: 0,
    closedIssues: 0,
  },
  descendantCounts: {
    openedEpics: 0,
    closedEpics: 0,
    openedIssues: 0,
    closedIssues: 0,
  },
  healthStatus: {
    issuesAtRisk: 0,
    issuesOnTrack: 0,
    issuesNeedingAttention: 0,
  },

  // Add Item Form Data
  issuableType: null,
  itemInputValue: '',
  pendingReferences: [],
  itemAutoCompleteSources: {},
  itemAddFailureType: null,
  itemAddFailureMessage: '',

  // UI Flags
  itemsFetchInProgress: false,
  itemsFetchFailure: false,
  itemsFetchResultEmpty: false,
  itemAddInProgress: false,
  itemAddFailure: false,
  itemCreateInProgress: false,
  projectsFetchInProgress: false,
  showAddItemForm: false,
  showCreateEpicForm: false,
  showCreateIssueForm: false,
  autoCompleteEpics: false,
  autoCompleteIssues: false,
  allowIssuableHealthStatus: false,
  allowScopedLabels: false,
  allowSubEpics: false,
  epicsWebUrl: '',
  issuesWebUrl: '',
  isShowingLabels: false,

  removeItemModalProps: {
    parentItem: {},
    item: {},
  },

  projects: [],

  descendantGroups: [],
  descendantGroupsFetchInProgress: false,
  defaultProjectForIssueCreation: null,
});
