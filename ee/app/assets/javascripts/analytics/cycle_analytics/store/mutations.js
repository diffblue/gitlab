import Vue from 'vue';
import {
  PAGINATION_SORT_FIELD_END_EVENT,
  PAGINATION_SORT_DIRECTION_DESC,
} from '~/analytics/cycle_analytics/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { transformRawStages, prepareStageErrors, formatMedianValuesWithOverview } from '../utils';
import * as types from './mutation_types';

export default {
  [types.SET_FEATURES](state, features) {
    state.features = features;
  },
  [types.SET_SELECTED_PROJECTS](state, projects) {
    state.selectedProjects = projects;
  },
  [types.SET_SELECTED_STAGE](state, rawData) {
    state.selectedStage = convertObjectPropsToCamelCase(rawData);
  },
  [types.SET_DATE_RANGE](state, { createdBefore, createdAfter }) {
    state.createdBefore = createdBefore;
    state.createdAfter = createdAfter;
  },
  [types.SET_STAGE_EVENTS](state, data = []) {
    state.formEvents = data.map((ev) => convertObjectPropsToCamelCase(ev, { deep: true }));
  },
  [types.REQUEST_VALUE_STREAM_DATA](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_VALUE_STREAM_DATA_SUCCESS](state) {
    state.errorCode = null;
    state.isLoading = false;
  },
  [types.RECEIVE_VALUE_STREAM_DATA_ERROR](state, errCode) {
    state.errorCode = errCode;
    state.isLoading = false;
  },
  [types.REQUEST_STAGE_DATA](state) {
    state.isLoadingStage = true;
    state.selectedStageError = '';
    state.selectedStageEvents = [];
    state.pagination = {};
  },
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, events = []) {
    state.selectedStageEvents = events.map((fields) =>
      convertObjectPropsToCamelCase(fields, { deep: true }),
    );
    state.isLoadingStage = false;
    state.selectedStageError = '';
  },
  [types.RECEIVE_STAGE_DATA_ERROR](state, message) {
    state.isLoadingStage = false;
    state.selectedStageError = message;
    state.selectedStageEvents = [];
    state.pagination = {};
  },
  [types.REQUEST_STAGE_MEDIANS](state) {
    state.medians = {};
  },
  [types.RECEIVE_STAGE_MEDIANS_SUCCESS](state, medians = []) {
    state.medians = formatMedianValuesWithOverview(medians);
  },
  [types.RECEIVE_STAGE_MEDIANS_ERROR](state) {
    state.medians = {};
  },
  [types.REQUEST_STAGE_COUNTS](state) {
    state.stageCounts = {};
  },
  [types.RECEIVE_STAGE_COUNTS_SUCCESS](state, stageCounts = []) {
    state.stageCounts = stageCounts.reduce(
      (acc, { id, count }) => ({
        ...acc,
        [id]: count,
      }),
      {},
    );
  },
  [types.RECEIVE_STAGE_COUNTS_ERROR](state) {
    state.stageCounts = {};
  },
  [types.REQUEST_GROUP_STAGES](state) {
    state.stages = [];
  },
  [types.RECEIVE_GROUP_STAGES_ERROR](state) {
    state.stages = [];
  },
  [types.RECEIVE_GROUP_STAGES_SUCCESS](state, stages) {
    state.stages = transformRawStages(stages);
  },
  [types.REQUEST_GROUP_LABELS](state) {
    state.isFetchingGroupLabels = true;
    state.defaultGroupLabels = [];
  },
  [types.RECEIVE_GROUP_LABELS_ERROR](state) {
    state.isFetchingGroupLabels = false;
    state.defaultGroupLabels = [];
  },
  [types.RECEIVE_GROUP_LABELS_SUCCESS](state, groupLabels = []) {
    state.isFetchingGroupLabels = false;
    state.defaultGroupLabels = groupLabels.map(convertObjectPropsToCamelCase);
  },
  [types.INITIALIZE_VSA](
    state,
    {
      groupPath = null,
      createdAfter = null,
      createdBefore = null,
      selectedProjects = [],
      selectedValueStream = {},
      defaultStageConfig = [],
      pagination = {},
      aggregation = {},
      namespace = {},
      enableTasksByTypeChart = false,
      enableCustomizableStages = false,
      enableProjectsFilter = false,
      projectId = null,
    } = {},
  ) {
    state.isLoading = true;
    state.projectId = projectId;
    state.groupPath = groupPath;
    state.selectedProjects = selectedProjects;
    state.selectedValueStream = selectedValueStream;
    state.createdBefore = createdBefore;
    state.createdAfter = createdAfter;
    state.defaultStageConfig = defaultStageConfig;
    state.namespace = namespace;
    state.enableTasksByTypeChart = enableTasksByTypeChart;
    state.enableCustomizableStages = enableCustomizableStages;
    state.enableProjectsFilter = enableProjectsFilter;

    Vue.set(state, 'aggregation', aggregation);

    Vue.set(state, 'pagination', {
      page: pagination.page ?? state.pagination.page,
      sort: pagination.sort ?? state.pagination.sort,
      direction: pagination.direction ?? state.pagination.direction,
    });
  },
  [types.INITIALIZE_VALUE_STREAM_SUCCESS](state) {
    state.isLoading = false;
  },
  [types.REQUEST_CREATE_VALUE_STREAM](state) {
    state.isCreatingValueStream = true;
    state.createValueStreamErrors = {};
  },
  [types.RECEIVE_CREATE_VALUE_STREAM_ERROR](state, { data: { stages = [] }, errors = {} }) {
    const { stages: stageErrors = {}, ...rest } = errors;
    state.createValueStreamErrors = { ...rest, stages: prepareStageErrors(stages, stageErrors) };
    state.isCreatingValueStream = false;
  },
  [types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS](state, valueStream = {}) {
    state.isCreatingValueStream = false;
    state.createValueStreamErrors = {};
    state.selectedValueStream = convertObjectPropsToCamelCase(valueStream, { deep: true });

    const { stages = [] } = valueStream;
    state.stages = transformRawStages(stages);
  },
  [types.REQUEST_UPDATE_VALUE_STREAM](state) {
    state.isEditingValueStream = true;
    state.createValueStreamErrors = {};
  },
  [types.RECEIVE_UPDATE_VALUE_STREAM_ERROR](state, { data: { stages = [] }, errors = {} }) {
    const { stages: stageErrors = {}, ...rest } = errors;
    state.createValueStreamErrors = { ...rest, stages: prepareStageErrors(stages, stageErrors) };
    state.isEditingValueStream = false;
  },
  [types.RECEIVE_UPDATE_VALUE_STREAM_SUCCESS](state, valueStream) {
    state.isEditingValueStream = false;
    state.createValueStreamErrors = {};
    state.selectedValueStream = convertObjectPropsToCamelCase(valueStream, { deep: true });
  },
  [types.REQUEST_DELETE_VALUE_STREAM](state) {
    state.isDeletingValueStream = true;
    state.deleteValueStreamError = null;
  },
  [types.RECEIVE_DELETE_VALUE_STREAM_ERROR](state, message) {
    state.isDeletingValueStream = false;
    state.deleteValueStreamError = message;
  },
  [types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS](state) {
    state.isDeletingValueStream = false;
    state.deleteValueStreamError = null;
    state.selectedValueStream = null;
  },
  [types.SET_SELECTED_VALUE_STREAM](state, valueStream) {
    state.selectedValueStream = convertObjectPropsToCamelCase(valueStream, { deep: true });
  },
  [types.REQUEST_VALUE_STREAMS](state) {
    state.isLoadingValueStreams = true;
    state.valueStreams = [];
  },
  [types.RECEIVE_VALUE_STREAMS_ERROR](state, errCode) {
    state.errCode = errCode;
    state.isLoadingValueStreams = false;
    state.valueStreams = [];
  },
  [types.RECEIVE_VALUE_STREAMS_SUCCESS](state, data) {
    state.isLoadingValueStreams = false;
    state.valueStreams = data
      .map(convertObjectPropsToCamelCase)
      .sort(({ name: aName = '' }, { name: bName = '' }) => {
        return aName.toUpperCase() > bName.toUpperCase() ? 1 : -1;
      });
  },
  [types.SET_PAGINATION](state, { page, hasNextPage, sort, direction }) {
    Vue.set(state, 'pagination', {
      page,
      hasNextPage,
      sort: sort || PAGINATION_SORT_FIELD_END_EVENT,
      direction: direction || PAGINATION_SORT_DIRECTION_DESC,
    });
  },
  [types.SET_CREATING_AGGREGATION](state, value) {
    state.isCreatingAggregation = value;
  },
};
