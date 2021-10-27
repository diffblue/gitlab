import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/threat_monitoring/store/modules/threat_monitoring/actions';
import * as types from 'ee/threat_monitoring/store/modules/threat_monitoring/mutation_types';
import getInitialState from 'ee/threat_monitoring/store/modules/threat_monitoring/state';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

import { mockEnvironmentsResponse } from '../../../mocks/mock_data';

jest.mock('~/flash');

const environmentsEndpoint = 'environmentsEndpoint';
const networkPolicyStatisticsEndpoint = 'networkPolicyStatisticsEndpoint';
const nextPage = 2;

describe('Threat Monitoring actions', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  afterEach(() => {
    createFlash.mockClear();
  });

  describe('threatMonitoring/setStatisticsEndpoint', () => {
    it('commits the SET_ENDPOINT mutation', () =>
      testAction(
        actions.setStatisticsEndpoint,
        networkPolicyStatisticsEndpoint,
        state,
        [
          {
            type: `threatMonitoringNetworkPolicy/${types.SET_ENDPOINT}`,
            payload: networkPolicyStatisticsEndpoint,
          },
        ],
        [],
      ));
  });

  describe('threatMonitoring/setEnvironmentEndpoint', () => {
    it('commits the SET_ENDPOINT mutation', () =>
      testAction(
        actions.setEnvironmentEndpoint,
        environmentsEndpoint,
        state,
        [
          {
            type: types.SET_ENDPOINT,
            payload: environmentsEndpoint,
          },
        ],
        [],
      ));
  });

  describe('requestEnvironments', () => {
    it('commits the REQUEST_ENVIRONMENTS mutation', () =>
      testAction(
        actions.requestEnvironments,
        undefined,
        state,
        [
          {
            type: types.REQUEST_ENVIRONMENTS,
          },
        ],
        [],
      ));
  });

  describe('receiveEnvironmentsSuccess', () => {
    const environments = [{ id: 1, name: 'production' }];

    it('commits the RECEIVE_ENVIRONMENTS_SUCCESS mutation', () =>
      testAction(
        actions.receiveEnvironmentsSuccess,
        environments,
        state,
        [
          {
            type: types.RECEIVE_ENVIRONMENTS_SUCCESS,
            payload: environments,
          },
        ],
        [],
      ));
  });

  describe('receiveEnvironmentsError', () => {
    it('commits the RECEIVE_ENVIRONMENTS_ERROR mutation', () =>
      testAction(
        actions.receiveEnvironmentsError,
        undefined,
        state,
        [
          {
            type: types.RECEIVE_ENVIRONMENTS_ERROR,
          },
        ],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalled();
      }));
  });

  describe('fetchEnvironments', () => {
    let mock;

    beforeEach(() => {
      state.environmentsEndpoint = environmentsEndpoint;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet(environmentsEndpoint)
          .replyOnce(httpStatus.OK, mockEnvironmentsResponse, { 'x-next-page': nextPage });
      });

      it('should dispatch the request and success actions', () =>
        testAction(
          actions.fetchEnvironments,
          undefined,
          state,
          [],
          [
            { type: 'requestEnvironments' },
            {
              type: 'receiveEnvironmentsSuccess',
              payload: { environments: mockEnvironmentsResponse.environments, nextPage },
            },
          ],
        ));
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(environmentsEndpoint).replyOnce(500);
      });

      it('should dispatch the request and error actions', () =>
        testAction(
          actions.fetchEnvironments,
          undefined,
          state,
          [],
          [{ type: 'requestEnvironments' }, { type: 'receiveEnvironmentsError' }],
        ));
    });

    describe('with an empty endpoint', () => {
      beforeEach(() => {
        state.environmentsEndpoint = '';
      });

      it('should dispatch receiveEnvironmentsError', () =>
        testAction(
          actions.fetchEnvironments,
          undefined,
          state,
          [],
          [{ type: 'receiveEnvironmentsError' }],
        ));
    });
  });

  describe('setCurrentEnvironmentId', () => {
    const environmentId = 1;

    it('commits the SET_CURRENT_ENVIRONMENT_ID mutation', () =>
      testAction(
        actions.setCurrentEnvironmentId,
        environmentId,
        state,
        [{ type: types.SET_CURRENT_ENVIRONMENT_ID, payload: environmentId }],
        [],
      ));
  });

  describe('setCurrentTimeWindow', () => {
    const timeWindow = { name: 'foo' };

    it('commits the SET_CURRENT_TIME_WINDOW mutation', () =>
      testAction(
        actions.setCurrentTimeWindow,
        timeWindow,
        state,
        [{ type: types.SET_CURRENT_TIME_WINDOW, payload: timeWindow.name }],
        [],
      ));
  });

  describe('setAllEnvironments', () => {
    it('commits the SET_ALL_ENVIRONMENTS mutation and dispatches Network Policy fetch action', () =>
      testAction(actions.setAllEnvironments, null, state, [{ type: types.SET_ALL_ENVIRONMENTS }]));
  });
});
