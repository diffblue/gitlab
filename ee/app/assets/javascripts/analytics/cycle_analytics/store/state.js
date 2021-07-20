import {
  PAGINATION_SORT_FIELD_END_EVENT,
  PAGINATION_SORT_DIRECTION_DESC,
} from '~/cycle_analytics/constants';

export default () => ({
  featureFlags: {},
  defaultStageConfig: [],

  createdAfter: null,
  createdBefore: null,

  isLoading: false,
  isLoadingStage: false,

  errorCode: null,

  currentGroup: null,
  selectedProjects: [],
  selectedStage: null,
  selectedValueStream: null,

  selectedStageEvents: [],

  isLoadingValueStreams: false,
  isCreatingValueStream: false,
  isEditingValueStream: false,
  isDeletingValueStream: false,

  createValueStreamErrors: {},
  deleteValueStreamError: null,

  stages: [],
  formEvents: [],
  selectedStageError: '',
  summary: [],
  medians: {},
  valueStreams: [],

  pagination: {
    page: null,
    hasNextPage: false,
    sort: PAGINATION_SORT_FIELD_END_EVENT,
    direction: PAGINATION_SORT_DIRECTION_DESC,
  },
  stageCounts: {},
});
