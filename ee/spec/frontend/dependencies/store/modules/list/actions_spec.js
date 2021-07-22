import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { sortBy } from 'lodash';
import * as actions from 'ee/dependencies/store/modules/list/actions';
import {
  FILTER,
  SORT_DESCENDING,
  FETCH_ERROR_MESSAGE,
} from 'ee/dependencies/store/modules/list/constants';
import * as types from 'ee/dependencies/store/modules/list/mutation_types';
import getInitialState from 'ee/dependencies/store/modules/list/state';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';

import mockDependenciesResponse from './data/mock_dependencies.json';

jest.mock('~/flash');

describe('Dependencies actions', () => {
  const pageInfo = {
    page: 3,
    nextPage: 2,
    previousPage: 1,
    perPage: 20,
    total: 100,
    totalPages: 5,
  };

  const headers = {
    'X-Next-Page': pageInfo.nextPage,
    'X-Page': pageInfo.page,
    'X-Per-Page': pageInfo.perPage,
    'X-Prev-Page': pageInfo.previousPage,
    'X-Total': pageInfo.total,
    'X-Total-Pages': pageInfo.totalPages,
  };

  afterEach(() => {
    createFlash.mockClear();
  });

  describe('setDependenciesEndpoint', () => {
    it('commits the SET_DEPENDENCIES_ENDPOINT mutation', () =>
      testAction(
        actions.setDependenciesEndpoint,
        TEST_HOST,
        getInitialState(),
        [
          {
            type: types.SET_DEPENDENCIES_ENDPOINT,
            payload: TEST_HOST,
          },
        ],
        [],
      ));
  });

  describe('setInitialState', () => {
    it('commits the SET_INITIAL_STATE mutation', () => {
      const payload = { filter: 'foo' };

      return testAction(
        actions.setInitialState,
        payload,
        getInitialState(),
        [
          {
            type: types.SET_INITIAL_STATE,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('requestDependencies', () => {
    it('commits the REQUEST_DEPENDENCIES mutation', () =>
      testAction(
        actions.requestDependencies,
        undefined,
        getInitialState(),
        [
          {
            type: types.REQUEST_DEPENDENCIES,
          },
        ],
        [],
      ));
  });

  describe('receiveDependenciesSuccess', () => {
    it('commits the RECEIVE_DEPENDENCIES_SUCCESS mutation', () =>
      testAction(
        actions.receiveDependenciesSuccess,
        { headers, data: mockDependenciesResponse },
        getInitialState(),
        [
          {
            type: types.RECEIVE_DEPENDENCIES_SUCCESS,
            payload: {
              dependencies: mockDependenciesResponse.dependencies,
              reportInfo: mockDependenciesResponse.report,
              pageInfo,
            },
          },
        ],
        [],
      ));
  });

  describe('receiveDependenciesError', () => {
    it('commits the RECEIVE_DEPENDENCIES_ERROR mutation', () => {
      const error = { error: true };

      return testAction(
        actions.receiveDependenciesError,
        error,
        getInitialState(),
        [
          {
            type: types.RECEIVE_DEPENDENCIES_ERROR,
            payload: error,
          },
        ],
        [],
      );
    });
  });

  describe('fetchDependencies', () => {
    const dependenciesPackagerDescending = {
      ...mockDependenciesResponse,
      dependencies: sortBy(mockDependenciesResponse.dependencies, 'packager').reverse(),
    };

    let state;
    let mock;

    beforeEach(() => {
      state = getInitialState();
      state.endpoint = `${TEST_HOST}/dependencies`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when endpoint is empty', () => {
      beforeEach(() => {
        state.endpoint = '';
      });

      it('does nothing', () => testAction(actions.fetchDependencies, undefined, state, [], []));
    });

    describe('on success', () => {
      describe('given no params', () => {
        beforeEach(() => {
          state.pageInfo = { ...pageInfo };

          const paramsDefault = {
            sort_by: state.sortField,
            sort: state.sortOrder,
            page: state.pageInfo.page,
            filter: state.filter,
          };

          mock
            .onGet(state.endpoint, { params: paramsDefault })
            .replyOnce(200, mockDependenciesResponse, headers);
        });

        it('uses default sorting params from state', () =>
          testAction(
            actions.fetchDependencies,
            undefined,
            state,
            [],
            [
              {
                type: 'requestDependencies',
              },
              {
                type: 'receiveDependenciesSuccess',
                payload: expect.objectContaining({ data: mockDependenciesResponse, headers }),
              },
            ],
          ));
      });

      describe('given params', () => {
        const paramsGiven = {
          sort_by: 'packager',
          sort: SORT_DESCENDING,
          page: 4,
          filter: FILTER.vulnerable,
        };

        beforeEach(() => {
          mock
            .onGet(state.endpoint, { params: paramsGiven })
            .replyOnce(200, dependenciesPackagerDescending, headers);
        });

        it('overrides default params', () =>
          testAction(
            actions.fetchDependencies,
            paramsGiven,
            state,
            [],
            [
              {
                type: 'requestDependencies',
              },
              {
                type: 'receiveDependenciesSuccess',
                payload: expect.objectContaining({ data: dependenciesPackagerDescending, headers }),
              },
            ],
          ));
      });
    });

    describe.each`
      responseType             | responseDetails
      ${'an invalid response'} | ${[200, { foo: 'bar' }]}
      ${'a response error'}    | ${[500]}
    `('given $responseType', ({ responseDetails }) => {
      beforeEach(() => {
        mock.onGet(state.endpoint).replyOnce(...responseDetails);
      });

      it('dispatches the receiveDependenciesError action and creates a flash', () =>
        testAction(
          actions.fetchDependencies,
          undefined,
          state,
          [],
          [
            {
              type: 'requestDependencies',
            },
            {
              type: 'receiveDependenciesError',
              payload: expect.any(Error),
            },
          ],
        ).then(() => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith({
            message: FETCH_ERROR_MESSAGE,
          });
        }));
    });
  });

  describe('setSortField', () => {
    it('commits the SET_SORT_FIELD mutation and dispatch the fetchDependencies action', () => {
      const field = 'packager';

      return testAction(
        actions.setSortField,
        field,
        getInitialState(),
        [
          {
            type: types.SET_SORT_FIELD,
            payload: field,
          },
        ],
        [
          {
            type: 'fetchDependencies',
            payload: { page: 1 },
          },
        ],
      );
    });
  });

  describe('toggleSortOrder', () => {
    it('commits the TOGGLE_SORT_ORDER mutation and dispatch the fetchDependencies action', () =>
      testAction(
        actions.toggleSortOrder,
        undefined,
        getInitialState(),
        [
          {
            type: types.TOGGLE_SORT_ORDER,
          },
        ],
        [
          {
            type: 'fetchDependencies',
            payload: { page: 1 },
          },
        ],
      ));
  });
});
