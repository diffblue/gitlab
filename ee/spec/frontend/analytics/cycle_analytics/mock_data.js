import { uniq } from 'lodash';
import {
  TASKS_BY_TYPE_SUBJECT_ISSUE,
  OVERVIEW_STAGE_CONFIG,
} from 'ee/analytics/cycle_analytics/constants';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';
import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import {
  getTasksByTypeData,
  transformRawTasksByTypeData,
} from 'ee/analytics/cycle_analytics/utils';
import { toYmd } from 'ee/analytics/shared/utils';
import { getJSONFixture } from 'helpers/fixtures';
import {
  getStageByTitle,
  defaultStages,
  rawStageMedians,
  createdBefore,
  createdAfter,
} from 'jest/cycle_analytics/mock_data';
import {
  PAGINATION_TYPE,
  PAGINATION_SORT_DIRECTION_DESC,
  PAGINATION_SORT_FIELD_END_EVENT,
} from '~/cycle_analytics/constants';
import { transformStagesForPathNavigation } from '~/cycle_analytics/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getDatesInRange } from '~/lib/utils/datetime_utility';

const fixtureEndpoints = {
  customizableCycleAnalyticsStagesAndEvents: 'analytics/value_stream_analytics/stages.json', // customizable stages and events endpoint
  stageEvents: (stage) => `analytics/value_stream_analytics/stages/${stage}/records.json`,
  stageMedian: (stage) => `analytics/value_stream_analytics/stages/${stage}/median.json`,
  stageCount: (stage) => `analytics/value_stream_analytics/stages/${stage}/count.json`,
  recentActivityData: 'analytics/metrics/value_stream_analytics/summary.json',
  timeMetricsData: 'analytics/metrics/value_stream_analytics/time_summary.json',
  groupLabels: 'api/group_labels.json',
};

export const endpoints = {
  groupLabels: /groups\/[A-Z|a-z|\d|\-|_]+\/-\/labels.json/,
  recentActivityData: /analytics\/value_stream_analytics\/summary/,
  timeMetricsData: /analytics\/value_stream_analytics\/time_summary/,
  durationData: /analytics\/value_stream_analytics\/value_streams\/\w+\/stages\/\w+\/average_duration_chart/,
  stageData: /analytics\/value_stream_analytics\/value_streams\/\w+\/stages\/\w+\/records/,
  stageMedian: /analytics\/value_stream_analytics\/value_streams\/\w+\/stages\/\w+\/median/,
  stageCount: /analytics\/value_stream_analytics\/value_streams\/\w+\/stages\/\w+\/count/,
  baseStagesEndpoint: /analytics\/value_stream_analytics\/value_streams\/\w+\/stages$/,
  tasksByTypeData: /analytics\/type_of_work\/tasks_by_type/,
  tasksByTypeTopLabelsData: /analytics\/type_of_work\/tasks_by_type\/top_labels/,
  valueStreamData: /analytics\/value_stream_analytics\/value_streams/,
};

export const valueStreams = [
  { id: 1, name: 'Value stream 1' },
  { id: 2, name: 'Value stream 2' },
];

export const groupLabels = getJSONFixture(fixtureEndpoints.groupLabels).map(
  convertObjectPropsToCamelCase,
);

export const recentActivityData = getJSONFixture(fixtureEndpoints.recentActivityData);
export const timeMetricsData = getJSONFixture(fixtureEndpoints.timeMetricsData);

export const customizableStagesAndEvents = getJSONFixture(
  fixtureEndpoints.customizableCycleAnalyticsStagesAndEvents,
);

const dummyState = {};

export const defaultStageConfig = [
  {
    name: 'issue',
    custom: false,
    relativePosition: 1,
    startEventIdentifier: 'issue_created',
    endEventIdentifier: 'issue_stage_end',
  },
  {
    name: 'plan',
    custom: false,
    relativePosition: 2,
    startEventIdentifier: 'plan_stage_start',
    endEventIdentifier: 'issue_first_mentioned_in_commit',
  },
  {
    name: 'code',
    custom: false,
    relativePosition: 3,
    startEventIdentifier: 'code_stage_start',
    endEventIdentifier: 'merge_request_created',
  },
];

// prepare the raw stage data for our components
mutations[types.RECEIVE_GROUP_STAGES_SUCCESS](dummyState, customizableStagesAndEvents.stages);

export const issueStage = getStageByTitle(dummyState.stages, 'issue');
export const planStage = getStageByTitle(dummyState.stages, 'plan');
export const reviewStage = getStageByTitle(dummyState.stages, 'review');
export const codeStage = getStageByTitle(dummyState.stages, 'code');
export const testStage = getStageByTitle(dummyState.stages, 'test');
export const stagingStage = getStageByTitle(dummyState.stages, 'staging');

export const allowedStages = [issueStage, planStage, codeStage];

const deepCamelCase = (obj) => convertObjectPropsToCamelCase(obj, { deep: true });

const stageFixtures = defaultStages.reduce((acc, stage) => {
  const events = getJSONFixture(fixtureEndpoints.stageEvents(stage));
  return {
    ...acc,
    [stage]: events,
  };
}, {});

export const stageMedians = rawStageMedians.reduce(
  (acc, { id, value }) => ({
    ...acc,
    [id]: value,
  }),
  {},
);

export const stageMediansWithNumericIds = rawStageMedians.reduce((acc, { id, value }) => {
  const { id: stageId } = getStageByTitle(dummyState.stages, id);
  return {
    ...acc,
    [stageId]: value,
  };
}, {});

export const rawStageCounts = defaultStages.map((id) => ({
  id,
  ...getJSONFixture(fixtureEndpoints.stageCount(id)),
}));

// Once https://gitlab.com/gitlab-org/gitlab/-/issues/328422 is fixed
// we should be able to use the rawStageCounts for building
// the stage counts mock data
/*
export const stageCounts = rawStageCounts.reduce(
  (acc, { id, value }) => ({
    ...acc,
    [id]: value,
  }),
  {},
);
*/

export const stageCounts = rawStageMedians.reduce((acc, { id, value }) => {
  const { id: stageId } = getStageByTitle(dummyState.stages, id);
  return { ...acc, [stageId]: value };
}, {});

export const issueEvents = deepCamelCase(stageFixtures.issue);
export const planEvents = deepCamelCase(stageFixtures.plan);
export const reviewEvents = deepCamelCase(stageFixtures.review);
export const codeEvents = deepCamelCase(stageFixtures.code);
export const testEvents = deepCamelCase(stageFixtures.test);
export const stagingEvents = deepCamelCase(stageFixtures.staging);
export const rawCustomStage = {
  name: 'Coolest beans stage',
  title: 'Coolest beans stage',
  hidden: false,
  legend: '',
  description: '',
  id: 18,
  custom: true,
  start_event_identifier: 'issue_first_mentioned_in_commit',
  end_event_identifier: 'issue_first_added_to_board',
};

export const medians = stageMedians;

export const rawCustomStageEvents = customizableStagesAndEvents.events;
export const camelCasedStageEvents = rawCustomStageEvents.map(deepCamelCase);

export const customStageLabelEvents = camelCasedStageEvents.filter((ev) => ev.type === 'label');
export const customStageStartEvents = camelCasedStageEvents.filter((ev) => ev.canBeStartEvent);

// get all the possible end events
const allowedEndEventIds = new Set(customStageStartEvents.flatMap((e) => e.allowedEndEvents));
export const customStageEndEvents = camelCasedStageEvents.filter((ev) =>
  allowedEndEventIds.has(ev.identifier),
);

export const customStageEvents = uniq(
  [...customStageStartEvents, ...customStageEndEvents],
  false,
  (ev) => ev.identifier,
);

export const labelStartEvent = customStageLabelEvents[0];
export const labelEndEvent = customStageLabelEvents.find(
  (ev) => ev.identifier === labelStartEvent.allowedEndEvents[0],
);

const dateRange = getDatesInRange(createdAfter, createdBefore, toYmd);

export const apiTasksByTypeData = getJSONFixture(
  'analytics/charts/type_of_work/tasks_by_type.json',
).map((labelData) => {
  // add data points for our mock date range
  const maxValue = 10;
  const series = dateRange.map((date) => [date, Math.floor(Math.random() * Math.floor(maxValue))]);
  return {
    ...labelData,
    series,
  };
});

export const rawTasksByTypeData = transformRawTasksByTypeData(apiTasksByTypeData);
export const transformedTasksByTypeData = getTasksByTypeData(apiTasksByTypeData);

export const transformedStagePathData = transformStagesForPathNavigation({
  stages: [{ ...OVERVIEW_STAGE_CONFIG }, ...allowedStages],
  medians,
  stageCounts,
  selectedStage: issueStage,
});

export const tasksByTypeData = {
  seriesNames: ['Cool label', 'Normal label'],
  data: [
    [0, 1, 2],
    [5, 2, 3],
    [2, 4, 1],
  ],
  groupBy: ['Group 1', 'Group 2', 'Group 3'],
};

export const taskByTypeFilters = {
  currentGroup: {
    id: 22,
    name: 'Gitlab Org',
    fullName: 'Gitlab Org',
    fullPath: 'gitlab-org',
  },
  selectedProjectIds: [],
  startDate: new Date('2019-12-11'),
  endDate: new Date('2020-01-10'),
  subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
  selectedLabelIds: [1, 2, 3],
};

export const rawDurationData = [
  {
    average_duration_in_seconds: 1234000,
    date: '2019-01-01T00:00:00.000Z',
  },
  {
    average_duration_in_seconds: 4321000,
    date: '2019-01-02T00:00:00.000Z',
  },
];

export const transformedDurationData = [
  {
    slug: 1,
    selected: true,
    data: rawDurationData,
  },
  {
    slug: 2,
    selected: true,
    data: rawDurationData,
  },
];

export const flattenedDurationData = [
  { average_duration_in_seconds: 1234000, date: '2019-01-01' },
  { average_duration_in_seconds: 4321000, date: '2019-01-02' },
  { average_duration_in_seconds: 1234000, date: '2019-01-01' },
  { average_duration_in_seconds: 4321000, date: '2019-01-02' },
];

export const durationChartPlottableData = [
  ['2019-01-01', 14, '2019-01-01'],
  ['2019-01-02', 50, '2019-01-02'],
];

export const rawDurationMedianData = [
  {
    average_duration_in_seconds: 1234000,
    date: '2018-12-01T00:00:00.000Z',
  },
  {
    average_duration_in_seconds: 4321000,
    date: '2018-12-02T00:00:00.000Z',
  },
];

export const pathNavIssueMetric = 172800;

export const initialPaginationQuery = {
  page: 15,
  sort: PAGINATION_SORT_FIELD_END_EVENT,
  direction: PAGINATION_SORT_DIRECTION_DESC,
};

export const initialPaginationState = {
  ...initialPaginationQuery,
  page: null,
  hasNextPage: false,
};

export const basePaginationResult = {
  pagination: PAGINATION_TYPE,
  sort: PAGINATION_SORT_FIELD_END_EVENT,
  direction: PAGINATION_SORT_DIRECTION_DESC,
  page: null,
};
