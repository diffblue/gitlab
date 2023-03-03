import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { sortBy } from 'lodash';
import * as actions from 'ee/dependencies/store/modules/list/actions';
import {
  FILTER,
  SORT_DESCENDING,
  FETCH_ERROR_MESSAGE,
  FETCH_EXPORT_ERROR_MESSAGE,
  DEPENDENCIES_FILENAME,
} from 'ee/dependencies/store/modules/list/constants';
import * as types from 'ee/dependencies/store/modules/list/mutation_types';
import getInitialState from 'ee/dependencies/store/modules/list/state';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import download from '~/lib/utils/downloader';
import {
  HTTP_STATUS_CREATED,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';

import mockDependenciesResponse from './data/mock_dependencies.json';

jest.mock('~/alert');
jest.mock('~/lib/utils/downloader');

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

  const mockResponseExportEndpoint = {
    id: 1,
    has_finished: true,
    self: '/dependency_list_exports/1',
    download: '/dependency_list_exports/1/download',
  };

  afterEach(() => {
    createAlert.mockClear();
    download.mockClear();
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

  describe('setExportDependenciesEndpoint', () => {
    it('commits the SET_EXPORT_DEPENDENCIES_ENDPOINT mutation', () =>
      testAction(
        actions.setExportDependenciesEndpoint,
        TEST_HOST,
        getInitialState(),
        [
          {
            type: types.SET_EXPORT_DEPENDENCIES_ENDPOINT,
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
            .replyOnce(HTTP_STATUS_OK, mockDependenciesResponse, headers);
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
            .replyOnce(HTTP_STATUS_OK, dependenciesPackagerDescending, headers);
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
      ${'an invalid response'} | ${[HTTP_STATUS_OK, { foo: 'bar' }]}
      ${'a response error'}    | ${[HTTP_STATUS_INTERNAL_SERVER_ERROR]}
    `('given $responseType', ({ responseDetails }) => {
      beforeEach(() => {
        mock.onGet(state.endpoint).replyOnce(...responseDetails);
      });

      it('dispatches the receiveDependenciesError action and creates an alert', () =>
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
          expect(createAlert).toHaveBeenCalledTimes(1);
          expect(createAlert).toHaveBeenCalledWith({
            message: FETCH_ERROR_MESSAGE,
          });
        }));
    });
  });

  describe('fetchExport', () => {
    let state;
    let mock;

    beforeEach(() => {
      state = getInitialState();
      state.exportEndpoint = `${TEST_HOST}/dependency_list_exports`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when endpoint is empty', () => {
      beforeEach(() => {
        state.exportEndpoint = '';
      });

      it('does nothing', () => testAction(actions.fetchExport, undefined, state, [], []));
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onPost(state.exportEndpoint)
          .replyOnce(HTTP_STATUS_CREATED, mockResponseExportEndpoint);
      });

      it('sets SET_FETCHING_IN_PROGRESS and dispatches downloadExport', () =>
        testAction(
          actions.fetchExport,
          undefined,
          state,
          [
            {
              type: 'SET_FETCHING_IN_PROGRESS',
              payload: true,
            },
          ],
          [
            {
              type: 'downloadExport',
              payload: mockResponseExportEndpoint.self,
            },
          ],
        ));
    });

    describe('on success with status other than created (201)', () => {
      beforeEach(() => {
        mock.onPost(state.exportEndpoint).replyOnce(HTTP_STATUS_OK, mockResponseExportEndpoint);
      });

      it('does not dispatch downloadExport', () =>
        testAction(
          actions.fetchExport,
          undefined,
          state,
          [
            {
              type: 'SET_FETCHING_IN_PROGRESS',
              payload: true,
            },
            {
              type: 'SET_FETCHING_IN_PROGRESS',
              payload: false,
            },
          ],
          [],
        ));
    });

    describe('on failure', () => {
      beforeEach(() => {
        mock.onPost(state.exportEndpoint).replyOnce(HTTP_STATUS_NOT_FOUND);
      });

      it('does not dispatch downloadExport', () =>
        testAction(
          actions.fetchExport,
          undefined,
          state,
          [
            {
              type: 'SET_FETCHING_IN_PROGRESS',
              payload: true,
            },
            {
              type: 'SET_FETCHING_IN_PROGRESS',
              payload: false,
            },
          ],
          [],
        ).then(() => {
          expect(createAlert).toHaveBeenCalledTimes(1);
          expect(createAlert).toHaveBeenCalledWith({
            message: FETCH_EXPORT_ERROR_MESSAGE,
          });
        }));
    });
  });

  describe('downloadExport', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(mockResponseExportEndpoint.self)
          .replyOnce(HTTP_STATUS_OK, mockResponseExportEndpoint);
      });

      it('sets SET_FETCHING_IN_PROGRESS and calls download', () =>
        testAction(
          actions.downloadExport,
          mockResponseExportEndpoint.self,
          undefined,
          [
            {
              type: 'SET_FETCHING_IN_PROGRESS',
              payload: false,
            },
          ],
          [],
        ).then(() => {
          expect(download).toHaveBeenCalledTimes(1);
          expect(download).toHaveBeenCalledWith({
            url: mockResponseExportEndpoint.download,
            fileName: DEPENDENCIES_FILENAME,
          });
        }));
    });

    describe('on failure', () => {
      beforeEach(() => {
        mock.onGet(mockResponseExportEndpoint.self).replyOnce(HTTP_STATUS_NOT_FOUND);
      });

      it('sets SET_FETCHING_IN_PROGRESS', () =>
        testAction(
          actions.downloadExport,
          mockResponseExportEndpoint.self,
          undefined,
          [
            {
              type: 'SET_FETCHING_IN_PROGRESS',
              payload: false,
            },
          ],
          [],
        ).then(() => {
          expect(createAlert).toHaveBeenCalledTimes(1);
          expect(createAlert).toHaveBeenCalledWith({
            message: FETCH_EXPORT_ERROR_MESSAGE,
          });
          expect(download).toHaveBeenCalledTimes(0);
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
