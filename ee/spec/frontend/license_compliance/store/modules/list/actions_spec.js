import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/license_compliance/store/modules/list/actions';
import {
  FETCH_ERROR_MESSAGE,
  SORT_BY,
  SORT_ORDER,
} from 'ee/license_compliance/store/modules/list/constants';
import * as types from 'ee/license_compliance/store/modules/list/mutation_types';
import getInitialState from 'ee/license_compliance/store/modules/list/state';

import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

import mockLicensesResponse from './data/mock_licenses.json';

jest.mock('~/alert');

describe('Licenses actions', () => {
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
    createAlert.mockClear();
  });

  describe('setLicensesEndpoint', () => {
    it('commits the SET_LICENSES_ENDPOINT mutation', () =>
      testAction(
        actions.setLicensesEndpoint,
        TEST_HOST,
        getInitialState(),
        [
          {
            type: types.SET_LICENSES_ENDPOINT,
            payload: TEST_HOST,
          },
        ],
        [],
      ));
  });

  describe('requestLicenses', () => {
    it('commits the REQUEST_LICENSES mutation', () =>
      testAction(
        actions.requestLicenses,
        undefined,
        getInitialState(),
        [
          {
            type: types.REQUEST_LICENSES,
          },
        ],
        [],
      ));
  });

  describe('receiveLicensesSuccess', () => {
    it('commits the RECEIVE_LICENSES_SUCCESS mutation', () =>
      testAction(
        actions.receiveLicensesSuccess,
        { headers, data: mockLicensesResponse },
        getInitialState(),
        [
          {
            type: types.RECEIVE_LICENSES_SUCCESS,
            payload: {
              licenses: mockLicensesResponse.licenses,
              reportInfo: mockLicensesResponse.report,
              pageInfo,
            },
          },
        ],
        [],
      ));
  });

  describe('receiveLicensesError', () => {
    it('commits the RECEIVE_LICENSES_ERROR mutation', () => {
      const error = { error: true };

      return testAction(
        actions.receiveLicensesError,
        error,
        getInitialState(),
        [
          {
            type: types.RECEIVE_LICENSES_ERROR,
          },
        ],
        [],
      ).then(() => {
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: FETCH_ERROR_MESSAGE,
        });
      });
    });
  });

  describe('fetchLicenses', () => {
    let state;
    let mock;

    beforeEach(() => {
      state = getInitialState();
      state.endpoint = `${TEST_HOST}/licenses`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when endpoint is empty', () => {
      beforeEach(() => {
        state.endpoint = '';
      });

      it('returns a rejected promise', () =>
        expect(actions.fetchLicenses({ state })).rejects.toEqual(
          new Error('No endpoint provided'),
        ));
    });

    describe('on success', () => {
      describe('given no params', () => {
        beforeEach(() => {
          state.pageInfo = { ...pageInfo };

          const paramsDefault = {
            page: state.pageInfo.page,
            per_page: 10,
            sort_by: SORT_BY.CLASSIFICATION,
            sort_direction: SORT_ORDER.DESC,
          };

          mock
            .onGet(state.endpoint, { params: paramsDefault })
            .replyOnce(HTTP_STATUS_OK, mockLicensesResponse, headers);
        });

        it('uses default params from state', () =>
          testAction(
            actions.fetchLicenses,
            undefined,
            state,
            [],
            [
              {
                type: 'requestLicenses',
              },
              {
                type: 'receiveLicensesSuccess',
                payload: expect.objectContaining({ data: mockLicensesResponse, headers }),
              },
            ],
          ));
      });

      describe('given params', () => {
        const paramsGiven = {
          page: 4,
        };

        const paramsSent = {
          ...paramsGiven,
          per_page: 10,
          sort_by: SORT_BY.CLASSIFICATION,
          sort_direction: SORT_ORDER.DESC,
        };

        beforeEach(() => {
          mock
            .onGet(state.endpoint, { params: paramsSent })
            .replyOnce(HTTP_STATUS_OK, mockLicensesResponse, headers);
        });

        it('overrides default params', () =>
          testAction(
            actions.fetchLicenses,
            paramsGiven,
            state,
            [],
            [
              {
                type: 'requestLicenses',
              },
              {
                type: 'receiveLicensesSuccess',
                payload: expect.objectContaining({ data: mockLicensesResponse, headers }),
              },
            ],
          ));
      });
    });

    describe('given a response error', () => {
      beforeEach(() => {
        mock.onGet(state.endpoint).replyOnce([HTTP_STATUS_INTERNAL_SERVER_ERROR]);
      });

      it('dispatches the receiveLicensesError action and creates an alert', () =>
        testAction(
          actions.fetchLicenses,
          undefined,
          state,
          [],
          [
            {
              type: 'requestLicenses',
            },
            {
              type: 'receiveLicensesError',
              payload: expect.any(Error),
            },
          ],
        ));
    });
  });
});
