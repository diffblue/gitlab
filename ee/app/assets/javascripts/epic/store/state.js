export default () => ({
  // API Paths to Send/Receive Data
  endpoint: '',
  updateEndpoint: '',

  fullPath: '',
  groupPath: '',
  markdownPreviewPath: '',
  labelsPath: '',

  // URLs to use with links
  epicsWebUrl: '',
  labelsWebUrl: '',
  markdownDocsPath: '',
  newEpicWebUrl: '',

  // Flags
  canCreate: false,
  canUpdate: false,
  canDestroy: false,
  canAdmin: false,
  allowSubEpics: false,

  // Epic Information
  epicId: 0,
  namespace: '#',
  state: '',
  created: '',
  author: null,
  initialTitleHtml: '',
  initialTitleText: '',
  initialDescriptionHtml: '',
  initialDescriptionText: '',
  lockVersion: 0,

  startDateSourcingMilestoneTitle: '',
  startDateSourcingMilestoneDates: {
    startDate: '',
    dueDate: '',
  },
  startDateIsFixed: false,
  startDateFixed: '',
  startDateFromMilestones: '',
  startDate: '',
  dueDateSourcingMilestoneTitle: '',
  dueDateSourcingMilestoneDates: {
    startDate: '',
    dueDate: '',
  },
  dueDateIsFixed: '',
  dueDateFixed: '',
  dueDateFromMilestones: '',
  dueDate: '',
  labels: [],
  participants: [],
  subscribed: false,
  confidential: false,

  // Create Epic Props
  newEpicTitle: '',
  newEpicConfidential: false,

  // UI status flags
  epicStatusChangeInProgress: false,
  epicDeleteInProgress: false,
  epicStartDateSaveInProgress: false,
  epicDueDateSaveInProgress: false,
  epicLabelsSelectInProgress: false,
  epicSubscriptionToggleInProgress: false,
  epicCreateInProgress: false,
  sidebarCollapsed: false,
});
