// Fixtures generated by: spec/frontend/fixtures/runner.rb

// List queries
import allRunnersWithCreatorData from 'test_fixtures/graphql/ci/runner/list/all_runners.query.graphql.with_creator.json';
import allRunnersData from 'test_fixtures/graphql/ci/runner/list/all_runners.query.graphql.json';
import allRunnersDataPaginated from 'test_fixtures/graphql/ci/runner/list/all_runners.query.graphql.paginated.json';
import runnersCountData from 'test_fixtures/graphql/ci/runner/list/all_runners_count.query.graphql.json';
import groupRunnersData from 'test_fixtures/graphql/ci/runner/list/group_runners.query.graphql.json';
import groupRunnersDataPaginated from 'test_fixtures/graphql/ci/runner/list/group_runners.query.graphql.paginated.json';
import groupRunnersCountData from 'test_fixtures/graphql/ci/runner/list/group_runners_count.query.graphql.json';

// Register runner queries
import runnerForRegistration from 'test_fixtures/graphql/ci/runner/register/runner_for_registration.query.graphql.json';

// Show runner queries
import runnerCreateResult from 'test_fixtures/graphql/ci/runner/new/runner_create.mutation.graphql.json';
import runnerData from 'test_fixtures/graphql/ci/runner/show/runner.query.graphql.json';
import runnerWithGroupData from 'test_fixtures/graphql/ci/runner/show/runner.query.graphql.with_group.json';
import runnerProjectsData from 'test_fixtures/graphql/ci/runner/show/runner_projects.query.graphql.json';
import runnerJobsData from 'test_fixtures/graphql/ci/runner/show/runner_jobs.query.graphql.json';

// Edit runner queries
import runnerFormData from 'test_fixtures/graphql/ci/runner/edit/runner_form.query.graphql.json';

// New runner queries
import {
  DEFAULT_MEMBERSHIP,
  INSTANCE_TYPE,
  CREATED_DESC,
  CREATED_ASC,
  STATUS_ONLINE,
  STATUS_STALE,
  RUNNER_PAGE_SIZE,
} from '~/ci/runner/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';

const emptyPageInfo = {
  __typename: 'PageInfo',
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: '',
  endCursor: '',
};

// Other mock data

// Mock searches and their corresponding urls
export const mockSearchExamples = [
  {
    name: 'a default query',
    urlQuery: '',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      membership: DEFAULT_MEMBERSHIP,
      sort: CREATED_DESC,
      first: RUNNER_PAGE_SIZE,
    },
    isDefault: true,
  },
  {
    name: 'a single status',
    urlQuery: '?status[]=ONLINE',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [{ type: 'status', value: { data: STATUS_ONLINE, operator: '=' } }],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      membership: DEFAULT_MEMBERSHIP,
      status: STATUS_ONLINE,
      sort: CREATED_DESC,
      first: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'a single term text search',
    urlQuery: '?search=something',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [
        {
          type: FILTERED_SEARCH_TERM,
          value: { data: 'something' },
        },
      ],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      membership: DEFAULT_MEMBERSHIP,
      search: 'something',
      sort: CREATED_DESC,
      first: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'a two terms text search',
    urlQuery: '?search=something+else',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [
        {
          type: FILTERED_SEARCH_TERM,
          value: { data: 'something' },
        },
        {
          type: FILTERED_SEARCH_TERM,
          value: { data: 'else' },
        },
      ],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      membership: DEFAULT_MEMBERSHIP,
      search: 'something else',
      sort: CREATED_DESC,
      first: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'single instance type',
    urlQuery: '?runner_type[]=INSTANCE_TYPE',
    search: {
      runnerType: INSTANCE_TYPE,
      membership: DEFAULT_MEMBERSHIP,
      filters: [],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      type: INSTANCE_TYPE,
      membership: DEFAULT_MEMBERSHIP,
      sort: CREATED_DESC,
      first: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'multiple runner status',
    urlQuery: '?status[]=ONLINE&status[]=STALE',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [
        { type: 'status', value: { data: STATUS_ONLINE, operator: '=' } },
        { type: 'status', value: { data: STATUS_STALE, operator: '=' } },
      ],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      status: STATUS_ONLINE,
      membership: DEFAULT_MEMBERSHIP,
      sort: CREATED_DESC,
      first: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'multiple status, a single instance type and a non default sort',
    urlQuery: '?status[]=ONLINE&runner_type[]=INSTANCE_TYPE&sort=CREATED_ASC',
    search: {
      runnerType: INSTANCE_TYPE,
      membership: DEFAULT_MEMBERSHIP,
      filters: [{ type: 'status', value: { data: STATUS_ONLINE, operator: '=' } }],
      pagination: {},
      sort: CREATED_ASC,
    },
    graphqlVariables: {
      status: STATUS_ONLINE,
      type: INSTANCE_TYPE,
      membership: DEFAULT_MEMBERSHIP,
      sort: CREATED_ASC,
      first: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'a tag',
    urlQuery: '?tag[]=tag-1',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [{ type: 'tag', value: { data: 'tag-1', operator: '=' } }],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      membership: DEFAULT_MEMBERSHIP,
      tagList: ['tag-1'],
      first: RUNNER_PAGE_SIZE,
      sort: CREATED_DESC,
    },
  },
  {
    name: 'two tags',
    urlQuery: '?tag[]=tag-1&tag[]=tag-2',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [
        { type: 'tag', value: { data: 'tag-1', operator: '=' } },
        { type: 'tag', value: { data: 'tag-2', operator: '=' } },
      ],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      membership: DEFAULT_MEMBERSHIP,
      tagList: ['tag-1', 'tag-2'],
      first: RUNNER_PAGE_SIZE,
      sort: CREATED_DESC,
    },
  },
  {
    name: 'the next page',
    urlQuery: '?after=AFTER_CURSOR',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [],
      pagination: { after: 'AFTER_CURSOR' },
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      membership: DEFAULT_MEMBERSHIP,
      sort: CREATED_DESC,
      after: 'AFTER_CURSOR',
      first: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'the previous page',
    urlQuery: '?before=BEFORE_CURSOR',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [],
      pagination: { before: 'BEFORE_CURSOR' },
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      membership: DEFAULT_MEMBERSHIP,
      sort: CREATED_DESC,
      before: 'BEFORE_CURSOR',
      last: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'the next page filtered by a status, an instance type, tags and a non default sort',
    urlQuery:
      '?status[]=ONLINE&runner_type[]=INSTANCE_TYPE&tag[]=tag-1&tag[]=tag-2&sort=CREATED_ASC&after=AFTER_CURSOR',
    search: {
      runnerType: INSTANCE_TYPE,
      membership: DEFAULT_MEMBERSHIP,
      filters: [
        { type: 'status', value: { data: STATUS_ONLINE, operator: '=' } },
        { type: 'tag', value: { data: 'tag-1', operator: '=' } },
        { type: 'tag', value: { data: 'tag-2', operator: '=' } },
      ],
      pagination: { after: 'AFTER_CURSOR' },
      sort: CREATED_ASC,
    },
    graphqlVariables: {
      status: STATUS_ONLINE,
      type: INSTANCE_TYPE,
      membership: DEFAULT_MEMBERSHIP,
      tagList: ['tag-1', 'tag-2'],
      sort: CREATED_ASC,
      after: 'AFTER_CURSOR',
      first: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'paused runners',
    urlQuery: '?paused[]=true',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [{ type: 'paused', value: { data: 'true', operator: '=' } }],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      paused: true,
      membership: DEFAULT_MEMBERSHIP,
      sort: CREATED_DESC,
      first: RUNNER_PAGE_SIZE,
    },
  },
  {
    name: 'active runners',
    urlQuery: '?paused[]=false',
    search: {
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [{ type: 'paused', value: { data: 'false', operator: '=' } }],
      pagination: {},
      sort: CREATED_DESC,
    },
    graphqlVariables: {
      paused: false,
      membership: DEFAULT_MEMBERSHIP,
      sort: CREATED_DESC,
      first: RUNNER_PAGE_SIZE,
    },
  },
];

export const onlineContactTimeoutSecs = 2 * 60 * 60;
export const staleTimeoutSecs = 7889238; // Ruby's `3.months`

export const mockRegistrationToken = 'MOCK_REGISTRATION_TOKEN';
export const mockAuthenticationToken = 'MOCK_AUTHENTICATION_TOKEN';

export const newRunnerPath = '/runners/new';
export const emptyStateSvgPath = 'emptyStateSvgPath.svg';
export const emptyStateFilteredSvgPath = 'emptyStateFilteredSvgPath.svg';

export {
  allRunnersData,
  allRunnersWithCreatorData,
  allRunnersDataPaginated,
  runnersCountData,
  groupRunnersData,
  groupRunnersDataPaginated,
  groupRunnersCountData,
  emptyPageInfo,
  runnerData,
  runnerWithGroupData,
  runnerProjectsData,
  runnerJobsData,
  runnerFormData,
  runnerCreateResult,
  runnerForRegistration,
};
